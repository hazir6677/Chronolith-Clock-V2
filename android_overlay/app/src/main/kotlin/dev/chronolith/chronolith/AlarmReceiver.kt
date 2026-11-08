package dev.chronolith.chronolith

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("id") ?: return
        val label = intent.getStringExtra("label") ?: "Alarm"
        val kind = intent.getStringExtra("kind") ?: "alarm"
        val ringtoneUri = intent.getStringExtra("ringtoneUri") ?: ""
        val isSnooze = intent.getBooleanExtra("snooze", false)

        if (!isSnooze) AlarmScheduler.onFired(context, id)

        if (kind == "reminder") {
            showReminder(context, label)
            return
        }

        val svc = Intent(context, AlarmService::class.java).apply {
            action = AlarmService.ACTION_START
            putExtra("id", id)
            putExtra("label", label)
            putExtra("ringtoneUri", ringtoneUri)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(svc)
        } else {
            context.startService(svc)
        }
    }

    private fun showReminder(context: Context, label: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                REMINDER_CHANNEL, "Bedtime reminders", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Daily wind-down reminder before bed" }
            nm.createNotificationChannel(channel)
        }
        val openPi = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, REMINDER_CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        b.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(label)
            .setContentText("Time to start winding down for bed.")
            .setContentIntent(openPi)
            .setAutoCancel(true)
        nm.notify(REMINDER_NOTIFICATION_ID, b.build())
    }

    companion object {
        const val REMINDER_CHANNEL = "chronolith_reminder_channel_v1"
        const val REMINDER_NOTIFICATION_ID = 9002
    }
}
