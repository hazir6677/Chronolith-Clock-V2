package dev.chronolith.chronolith

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.util.Log

/**
 * Low-latency interface sounds (buttons, crown ticks, levers, flip digits) via SoundPool.
 * Samples live in res/raw. Uses the "sonification" usage so system volume and
 * do-not-disturb rules apply; the ambience loop never starts over other media.
 */
object SoundBridge {
    private val names = listOf(
        "button_click", "crown_tick", "lever_clack", "flip", "timer_complete", "gear_ambience"
    )
    private var pool: SoundPool? = null
    private val sampleIds = HashMap<String, Int>()
    private val ready = HashSet<Int>()
    private var ambienceStream = 0

    @Synchronized
    fun init(ctx: Context) {
        if (pool != null) return
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val sp = SoundPool.Builder().setMaxStreams(8).setAudioAttributes(attrs).build()
        sp.setOnLoadCompleteListener { _, id, status ->
            if (status == 0) synchronized(this) { ready.add(id) }
        }
        for (n in names) {
            val res = ctx.resources.getIdentifier(n, "raw", ctx.packageName)
            if (res != 0) sampleIds[n] = sp.load(ctx, res, 1)
            else Log.w("SoundBridge", "missing raw resource: $n")
        }
        pool = sp
    }

    @Synchronized
    fun play(name: String, volume: Float, rate: Float) {
        val sp = pool ?: return
        val id = sampleIds[name] ?: return
        if (!ready.contains(id)) return
        val v = volume.coerceIn(0f, 1f)
        sp.play(id, v, v, 1, 0, rate.coerceIn(0.5f, 2f))
    }

    @Synchronized
    fun startAmbience(ctx: Context, volume: Float) {
        val sp = pool ?: return
        val id = sampleIds["gear_ambience"] ?: return
        if (!ready.contains(id) || ambienceStream != 0) return
        val am = ctx.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        if (am?.isMusicActive == true) return // never layer over the user's media
        val v = volume.coerceIn(0f, 1f)
        ambienceStream = sp.play(id, v, v, 0, -1, 1f)
    }

    @Synchronized
    fun stopAmbience() {
        if (ambienceStream != 0) {
            pool?.stop(ambienceStream)
            ambienceStream = 0
        }
    }

    @Synchronized
    fun release() {
        stopAmbience()
        pool?.release()
        pool = null
        sampleIds.clear()
        ready.clear()
    }
}
