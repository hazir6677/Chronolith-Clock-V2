package dev.chronolith.chronolith

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Re-arms every saved alarm after reboot, app update, or clock/timezone change. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            AlarmScheduler.scheduleAll(context)
        } catch (e: Exception) {
            // Nothing sensible to do from a boot receiver.
        }
    }
}
