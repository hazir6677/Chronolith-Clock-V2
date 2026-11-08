package dev.chronolith.chronolith

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator

/** Foreground service that actually rings: loops the chosen sound + vibration until dismissed. */
class AlarmService : Service() {

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private val autoStop = Runnable { stopAlarm() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopAlarm()
                return START_NOT_STICKY
            }
            ACTION_SNOOZE -> {
                snooze(this)
                stopAlarm()
                return START_NOT_STICKY
            }
        }

        val id = intent?.getStringExtra("id") ?: "alarm"
        val label = intent?.getStringExtra("label") ?: "Alarm"
        val uri = intent?.getStringExtra("ringtoneUri") ?: ""

        cleanup()
        ringingId = id
        ringingLabel = label
        ringingUri = uri

        createChannel()
        val notification = buildNotification(label)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = pm?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Chronolith::AlarmWakeLock")
            wakeLock?.acquire(10 * 60 * 1000L)
        } catch (e: Exception) {
        }

        startSound(uri)
        startVibration()

        handler.removeCallbacks(autoStop)
        handler.postDelayed(autoStop, 10 * 60 * 1000L)
        return START_NOT_STICKY
    }

    private fun startSound(uriStr: String) {
        val defaultUri: Uri? = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

        val candidates = ArrayList<Uri>()
        if (uriStr.isNotEmpty()) candidates.add(Uri.parse(uriStr))
        if (defaultUri != null) candidates.add(defaultUri)

        for (u in candidates) {
            val mp = MediaPlayer()
            try {
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                mp.setDataSource(this, u)
                mp.isLooping = true
                mp.prepare()
                mp.start()
                player = mp
                return
            } catch (e: Exception) {
                try {
                    mp.release()
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun startVibration() {
        try {
            @Suppress("DEPRECATION")
            val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (v != null && v.hasVibrator()) {
                val pattern = longArrayOf(0, 600, 400, 600, 400, 800, 500)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createWaveform(pattern, 0))
                } else {
                    @Suppress("DEPRECATION")
                    v.vibrate(pattern, 0)
                }
                vibrator = v
            }
        } catch (e: Exception) {
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID, "Ringing alarms & timers", NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shown while an alarm or timer is ringing"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(label: String): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val openPi = PendingIntent.getActivity(this, 0, openIntent, flags)
        val stopPi = PendingIntent.getService(
            this, 1, Intent(this, AlarmService::class.java).setAction(ACTION_STOP), flags
        )
        val snoozePi = PendingIntent.getService(
            this, 2, Intent(this, AlarmService::class.java).setAction(ACTION_SNOOZE), flags
        )

        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_MAX)
        }
        b.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(label)
            .setContentText("Ringing now")
            .setContentIntent(openPi)
            .setFullScreenIntent(openPi, true)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
        @Suppress("DEPRECATION")
        b.addAction(android.R.drawable.ic_media_pause, "Snooze 10 min", snoozePi)
        @Suppress("DEPRECATION")
        b.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", stopPi)
        return b.build()
    }

    private fun cleanup() {
        handler.removeCallbacks(autoStop)
        try {
            player?.stop()
        } catch (_: Exception) {
        }
        try {
            player?.release()
        } catch (_: Exception) {
        }
        player = null
        try {
            vibrator?.cancel()
        } catch (_: Exception) {
        }
        vibrator = null
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (_: Exception) {
        }
        wakeLock = null
    }

    private fun stopAlarm() {
        cleanup()
        ringingId = null
        ringingLabel = null
        ringingUri = ""
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        cleanup()
        ringingId = null
        ringingLabel = null
        ringingUri = ""
        super.onDestroy()
    }

    companion object {
        const val ACTION_START = "dev.chronolith.chronolith.START_ALARM"
        const val ACTION_STOP = "dev.chronolith.chronolith.STOP_ALARM"
        const val ACTION_SNOOZE = "dev.chronolith.chronolith.SNOOZE_ALARM"
        const val CHANNEL_ID = "chronolith_alarm_channel_v3"
        const val NOTIFICATION_ID = 9001

        @Volatile var ringingId: String? = null
        @Volatile var ringingLabel: String? = null
        @Volatile var ringingUri: String = ""

        fun snooze(ctx: Context) {
            val id = ringingId ?: return
            AlarmScheduler.scheduleAt(
                ctx,
                id,
                System.currentTimeMillis() + AlarmScheduler.SNOOZE_MILLIS,
                ringingLabel ?: "Alarm",
                "alarm",
                ringingUri,
                true
            )
        }

        fun stop(ctx: Context) {
            ctx.stopService(Intent(ctx, AlarmService::class.java))
            (ctx.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
                ?.cancel(NOTIFICATION_ID)
        }
    }
}
