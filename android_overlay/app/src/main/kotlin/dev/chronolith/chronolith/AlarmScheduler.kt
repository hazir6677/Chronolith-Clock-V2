package dev.chronolith.chronolith

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Native alarm store + scheduler. Dart is the source of truth: every change
 * sends the full alarm list to [sync], which is persisted here so alarms can be
 * re-armed after a reboot and re-armed after each repeating alarm fires.
 */
object AlarmScheduler {
    private const val PREFS = "chronolith_native"
    private const val KEY_ALARMS = "alarms"
    private const val KEY_FIRED = "fired_oneshots"
    const val TIMER_ID = "__timer__"
    const val SNOOZE_MILLIS = 10 * 60 * 1000L

    private fun prefs(ctx: Context) =
        ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun loadAlarms(ctx: Context): JSONArray =
        try {
            JSONArray(prefs(ctx).getString(KEY_ALARMS, "[]"))
        } catch (e: Exception) {
            JSONArray()
        }

    private fun saveAlarms(ctx: Context, arr: JSONArray) {
        prefs(ctx).edit().putString(KEY_ALARMS, arr.toString()).apply()
    }

    fun sync(ctx: Context, incoming: JSONArray) {
        val old = loadAlarms(ctx)
        for (i in 0 until old.length()) {
            cancel(ctx, old.getJSONObject(i).optString("id"))
        }
        saveAlarms(ctx, incoming)
        scheduleAll(ctx)
    }

    fun scheduleAll(ctx: Context) {
        val arr = loadAlarms(ctx)
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            if (o.optBoolean("enabled", true)) scheduleNext(ctx, o)
        }
    }

    private fun intList(arr: JSONArray?): List<Int> {
        val out = ArrayList<Int>()
        if (arr != null) for (i in 0 until arr.length()) out.add(arr.getInt(i))
        return out
    }

    fun scheduleNext(ctx: Context, o: JSONObject, after: Long = System.currentTimeMillis()) {
        val trigger = nextTrigger(
            o.optInt("hour"),
            o.optInt("minute"),
            intList(o.optJSONArray("days")),
            after
        )
        scheduleAt(
            ctx,
            o.optString("id"),
            trigger,
            o.optString("label", "Alarm"),
            o.optString("kind", "alarm"),
            o.optString("ringtoneUri", ""),
            false
        )
    }

    /** isoDays: Mon=1..Sun=7. Empty list = one-time alarm. */
    fun nextTrigger(hour: Int, minute: Int, isoDays: List<Int>, after: Long): Long {
        for (offset in 0..7) {
            val c = Calendar.getInstance()
            c.timeInMillis = after
            c.add(Calendar.DAY_OF_YEAR, offset)
            c.set(Calendar.HOUR_OF_DAY, hour)
            c.set(Calendar.MINUTE, minute)
            c.set(Calendar.SECOND, 0)
            c.set(Calendar.MILLISECOND, 0)
            if (c.timeInMillis <= after) continue
            if (isoDays.isEmpty()) return c.timeInMillis
            val dow = c.get(Calendar.DAY_OF_WEEK)
            val iso = if (dow == Calendar.SUNDAY) 7 else dow - 1
            if (isoDays.contains(iso)) return c.timeInMillis
        }
        return after + 24L * 60L * 60L * 1000L
    }

    private fun requestCode(id: String, snooze: Boolean): Int =
        if (snooze) id.hashCode() xor 0x2F2F2F2F else id.hashCode()

    private fun pendingFor(
        ctx: Context,
        id: String,
        label: String,
        kind: String,
        ringtoneUri: String,
        snooze: Boolean
    ): PendingIntent {
        val intent = Intent(ctx, AlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("label", label)
            putExtra("kind", kind)
            putExtra("ringtoneUri", ringtoneUri)
            putExtra("snooze", snooze)
        }
        return PendingIntent.getBroadcast(
            ctx,
            requestCode(id, snooze),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun scheduleAt(
        ctx: Context,
        id: String,
        triggerAt: Long,
        label: String,
        kind: String,
        ringtoneUri: String,
        snooze: Boolean
    ) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pi = pendingFor(ctx, id, label, kind, ringtoneUri, snooze)
        val showPi = PendingIntent.getActivity(
            ctx,
            0,
            Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                am.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAt, showPi), pi)
            }
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }
    }

    fun cancel(ctx: Context, id: String) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        am.cancel(pendingFor(ctx, id, "", "alarm", "", false))
        am.cancel(pendingFor(ctx, id, "", "alarm", "", true))
    }

    fun scheduleTimer(ctx: Context, triggerAt: Long) {
        scheduleAt(ctx, TIMER_ID, triggerAt, "Timer", "alarm", "", false)
    }

    fun canScheduleExact(ctx: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        return am.canScheduleExactAlarms()
    }

    /** Called when an alarm fires: re-arm repeating alarms, retire one-time ones. */
    fun onFired(ctx: Context, id: String) {
        val arr = loadAlarms(ctx)
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            if (o.optString("id") != id) continue
            val days = intList(o.optJSONArray("days"))
            if (days.isEmpty()) {
                o.put("enabled", false)
                saveAlarms(ctx, arr)
                val fired = prefs(ctx).getStringSet(KEY_FIRED, emptySet())!!.toMutableSet()
                fired.add(id)
                prefs(ctx).edit().putStringSet(KEY_FIRED, fired).apply()
            } else {
                scheduleNext(ctx, o, System.currentTimeMillis() + 1000L)
            }
            return
        }
    }

    fun consumeFiredOneShots(ctx: Context): List<String> {
        val fired = prefs(ctx).getStringSet(KEY_FIRED, emptySet())!!.toList()
        prefs(ctx).edit().remove(KEY_FIRED).apply()
        return fired
    }
}
