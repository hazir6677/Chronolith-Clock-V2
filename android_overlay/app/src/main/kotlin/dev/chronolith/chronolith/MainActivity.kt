package dev.chronolith.chronolith

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private val channelName = "dev.chronolith.app/alarm"
    private val ringtoneRequest = 7001
    private var pendingRingtoneResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 101)
        }
    }

    private fun notificationsAllowed(): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SoundBridge.init(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.chronolith.app/sound")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        SoundBridge.play(
                            call.argument<String>("name") ?: "",
                            (call.argument<Number>("volume") ?: 1.0).toFloat(),
                            (call.argument<Number>("rate") ?: 1.0).toFloat()
                        )
                        result.success(null)
                    }
                    "startAmbience" -> {
                        SoundBridge.startAmbience(
                            applicationContext,
                            (call.argument<Number>("volume") ?: 0.25).toFloat()
                        )
                        result.success(null)
                    }
                    "stopAmbience" -> {
                        SoundBridge.stopAmbience()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickRingtone" -> {
                    if (pendingRingtoneResult != null) {
                        result.error("BUSY", "Ringtone picker already open", null)
                        return@setMethodCallHandler
                    }
                    pendingRingtoneResult = result
                    val current = call.argument<String>("currentUri")
                    try {
                        val defaultUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI, defaultUri)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Alarm sound")
                            putExtra(
                                RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                                if (!current.isNullOrEmpty()) Uri.parse(current) else defaultUri
                            )
                        }
                        startActivityForResult(intent, ringtoneRequest)
                    } catch (e: Exception) {
                        pendingRingtoneResult = null
                        result.success(null)
                    }
                }
                "syncAlarms" -> {
                    try {
                        val json = call.arguments as? String ?: "[]"
                        AlarmScheduler.sync(this, JSONArray(json))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SYNC_FAILED", e.message, null)
                    }
                }
                "scheduleTimer" -> {
                    val at = (call.argument<Number>("triggerAtMillis"))?.toLong()
                    if (at == null) {
                        result.error("BAD_ARGS", "triggerAtMillis missing", null)
                    } else {
                        AlarmScheduler.scheduleTimer(this, at)
                        result.success(true)
                    }
                }
                "cancelTimer" -> {
                    AlarmScheduler.cancel(this, AlarmScheduler.TIMER_ID)
                    result.success(true)
                }
                "getRingingStatus" -> {
                    val id = AlarmService.ringingId
                    result.success(
                        mapOf(
                            "isRinging" to (id != null),
                            "id" to (id ?: ""),
                            "label" to (AlarmService.ringingLabel ?: "")
                        )
                    )
                }
                "stopRinging" -> {
                    AlarmService.stop(this)
                    result.success(true)
                }
                "snoozeRinging" -> {
                    AlarmService.snooze(this)
                    AlarmService.stop(this)
                    result.success(true)
                }
                "consumeFiredOneShots" -> {
                    result.success(AlarmScheduler.consumeFiredOneShots(this))
                }
                "getPermissionStatus" -> {
                    result.success(
                        mapOf(
                            "notifications" to notificationsAllowed(),
                            "exactAlarms" to AlarmScheduler.canScheduleExact(this)
                        )
                    )
                }
                "openExactAlarmSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                    Uri.parse("package:$packageName")
                                )
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        SoundBridge.stopAmbience()
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != ringtoneRequest) return
        val callback = pendingRingtoneResult
        pendingRingtoneResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            callback?.success(null)
            return
        }
        @Suppress("DEPRECATION")
        val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        if (uri == null) {
            callback?.success(mapOf("uri" to "", "title" to "Default alarm sound"))
            return
        }
        val title = try {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this) ?: "Custom sound"
        } catch (e: Exception) {
            "Custom sound"
        }
        callback?.success(mapOf("uri" to uri.toString(), "title" to title))
    }
}
