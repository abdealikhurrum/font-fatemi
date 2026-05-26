package com.lisanuddawat.keyboard

import android.content.Context

object KeyboardSettings {

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences("lsd_keyboard_settings", Context.MODE_PRIVATE)

    // ── Layout ──────────────────────────────────────────────────────────

    enum class LayoutType(val key: String) {
        LSD("lsd"), ARABIC_STANDARD("arabic_standard"), CRULP_URDU("crulp_urdu")
    }

    fun getLayout(ctx: Context): LayoutType =
        LayoutType.values().firstOrNull { it.key == prefs(ctx).getString("selected_layout", "lsd") }
            ?: LayoutType.LSD

    fun setLayout(ctx: Context, v: LayoutType) =
        prefs(ctx).edit().putString("selected_layout", v.key).apply()

    // ── Predictions ──────────────────────────────────────────────────────

    fun getPredictions(ctx: Context): Boolean =
        prefs(ctx).getBoolean("prediction_enabled", false)

    fun setPredictions(ctx: Context, v: Boolean) =
        prefs(ctx).edit().putBoolean("prediction_enabled", v).apply()

    // ── Double-press ─────────────────────────────────────────────────────

    fun getDoublePressEnabled(ctx: Context): Boolean =
        prefs(ctx).getBoolean("double_press_enabled", true)

    fun setDoublePressEnabled(ctx: Context, v: Boolean) =
        prefs(ctx).edit().putBoolean("double_press_enabled", v).apply()

    fun getDoublePressWindowMs(ctx: Context): Long =
        prefs(ctx).getLong("double_press_window_ms", 400L)

    fun setDoublePressWindowMs(ctx: Context, v: Long) =
        prefs(ctx).edit().putLong("double_press_window_ms", v).apply()

    // ── Double-alef style ────────────────────────────────────────────────

    enum class DoubleAlefStyle(val key: String) {
        KHARO_ZABAR("kharo_zabar"),  // اٰ  default
        ALEF_MADDA("alef_madda")    // آ
    }

    fun getDoubleAlefStyle(ctx: Context): DoubleAlefStyle =
        DoubleAlefStyle.values().firstOrNull {
            it.key == prefs(ctx).getString("double_alef_style", "kharo_zabar")
        } ?: DoubleAlefStyle.KHARO_ZABAR

    fun setDoubleAlefStyle(ctx: Context, v: DoubleAlefStyle) =
        prefs(ctx).edit().putString("double_alef_style", v.key).apply()

    // ── Kaaf style ───────────────────────────────────────────────────────

    enum class KaafStyle(val key: String) {
        ARABIC_KAAF("arabic_kaaf"),   // ك  default
        URDU_KAAF("urdu_kaaf")        // ک
    }

    fun getKaafStyle(ctx: Context): KaafStyle =
        KaafStyle.values().firstOrNull { it.key == prefs(ctx).getString("kaaf_style", "arabic_kaaf") }
            ?: KaafStyle.ARABIC_KAAF

    fun setKaafStyle(ctx: Context, v: KaafStyle) =
        prefs(ctx).edit().putString("kaaf_style", v.key).apply()

    // ── Haa style ────────────────────────────────────────────────────────

    enum class HaaStyle(val key: String) {
        ARABIC_HAA("arabic_haa"),     // ه  default
        URDU_HAA("urdu_haa")          // ہ
    }

    fun getHaaStyle(ctx: Context): HaaStyle =
        HaaStyle.values().firstOrNull { it.key == prefs(ctx).getString("haa_style", "arabic_haa") }
            ?: HaaStyle.ARABIC_HAA

    fun setHaaStyle(ctx: Context, v: HaaStyle) =
        prefs(ctx).edit().putString("haa_style", v.key).apply()

    // ── Taa marbuta style ────────────────────────────────────────────────

    enum class TaaMarbuta(val key: String) {
        ARABIC_TAA("arabic_taa"),     // ة  default
        URDU_TAA("urdu_taa")          // ۃ
    }

    fun getTaaMarbuta(ctx: Context): TaaMarbuta =
        TaaMarbuta.values().firstOrNull { it.key == prefs(ctx).getString("taa_marbuta", "arabic_taa") }
            ?: TaaMarbuta.ARABIC_TAA

    fun setTaaMarbuta(ctx: Context, v: TaaMarbuta) =
        prefs(ctx).edit().putString("taa_marbuta", v.key).apply()

    // ── Yeh style (all layouts) ──────────────────────────────────────────

    enum class YehStyle(val key: String) {
        FARSI_YEH("farsi_yeh"),    // ی  default — standard in Urdu/Farsi
        ARABIC_YEH("arabic_yeh")  // ي
    }

    fun getYehStyle(ctx: Context): YehStyle =
        YehStyle.values().firstOrNull {
            it.key == prefs(ctx).getString("urdu_yeh_style", "arabic_yeh")
        } ?: YehStyle.ARABIC_YEH

    fun setYehStyle(ctx: Context, v: YehStyle) =
        prefs(ctx).edit().putString("urdu_yeh_style", v.key).apply()

    // ── BiDi tooltip ─────────────────────────────────────────────────────

    fun getBiDiTooltipShown(ctx: Context): Boolean =
        prefs(ctx).getBoolean("bidi_tooltip_shown", false)

    fun setBiDiTooltipShown(ctx: Context) =
        prefs(ctx).edit().putBoolean("bidi_tooltip_shown", true).apply()

    // ── Long-press behaviour ─────────────────────────────────────────────

    fun getLongPressDelayMs(ctx: Context): Long =
        prefs(ctx).getLong("long_press_delay_ms", 350L)

    fun setLongPressDelayMs(ctx: Context, v: Long) =
        prefs(ctx).edit().putLong("long_press_delay_ms", v).apply()

    // 0 = repeat disabled
    fun getPopupRepeatIntervalMs(ctx: Context): Long =
        prefs(ctx).getLong("popup_repeat_interval_ms", 100L)

    fun setPopupRepeatIntervalMs(ctx: Context, v: Long) =
        prefs(ctx).edit().putLong("popup_repeat_interval_ms", v).apply()

    // ── Latin key tooltip ─────────────────────────────────────────────────

    fun getLatinKeyTooltipShown(ctx: Context): Boolean =
        prefs(ctx).getBoolean("latin_key_tooltip_shown", false)

    fun setLatinKeyTooltipShown(ctx: Context) =
        prefs(ctx).edit().putBoolean("latin_key_tooltip_shown", true).apply()
}
