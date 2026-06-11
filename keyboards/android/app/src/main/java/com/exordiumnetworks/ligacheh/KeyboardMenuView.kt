package com.exordiumnetworks.ligacheh

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.widget.*

// Full-height settings panel that slides up over the keyboard area.
// Triggered from the ⚙ button in the predictive bar.
class KeyboardMenuView(context: Context) : FrameLayout(context) {

    /** Called when a setting that requires a layout reload changes. */
    var onApplyLayer: (() -> Unit)? = null

    private var doublePressSubSection: LinearLayout? = null

    companion object {
        fun show(parent: FrameLayout, onApplyLayer: () -> Unit): KeyboardMenuView {
            val menu = KeyboardMenuView(parent.context)
            menu.onApplyLayer = onApplyLayer
            parent.addView(menu, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
            val startY = parent.height.toFloat().coerceAtLeast(400f)
            menu.translationY = startY
            parent.post { menu.animate().translationY(0f).setDuration(220).start() }
            return menu
        }
    }

    init { buildUi() }

    // ── Build ────────────────────────────────────────────────────────────

    private fun buildUi() {
        setBackgroundColor(KeyboardColors.background(context))

        val root = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        addView(root, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        root.addView(buildHeader())
        root.addView(hairline())

        val scroll = ScrollView(context)
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(4), dp(16), dp(8))
        }
        scroll.addView(content)
        root.addView(scroll, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))

        buildContent(content)
    }

    private fun buildHeader(): View {
        val bar = FrameLayout(context).apply {
            setBackgroundColor(KeyboardColors.predictiveBar(context))
        }
        bar.addView(TextView(context).apply {
            text    = "Keyboard Settings"
            textSize = 14f
            setTypeface(null, Typeface.BOLD)
            setTextColor(KeyboardColors.keyLabel(context))
            gravity = Gravity.CENTER
        }, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, dp(44)))
        bar.addView(TextView(context).apply {
            text    = "Done"
            textSize = 14f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.parseColor("#007AFF"))
            setPadding(0, 0, dp(14), 0)
            gravity = Gravity.CENTER_VERTICAL or Gravity.END
            isClickable = true; isFocusable = true
            setOnClickListener { dismiss() }
        }, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, dp(44)))
        return bar
    }

    private fun buildContent(c: LinearLayout) {
        addLayoutRow(c)

        c.addView(hairline())

        addToggleRow(c, "Word predictions",
            get = { KeyboardSettings.getPredictions(context) },
            set = { KeyboardSettings.setPredictions(context, it) })

        c.addView(hairline())

        addToggleRow(c, "Roman typing on ABC (experimental)",
            get = { KeyboardSettings.getTranslitEnabled(context) },
            set = { KeyboardSettings.setTranslitEnabled(context, it) })

        c.addView(hairline())

        addToggleRow(c, "Corpus logging",
            get = { KeyboardSettings.getCorpusEnabled(context) },
            set = { KeyboardSettings.setCorpusEnabled(context, it) })

        c.addView(hairline())

        addDoublePressSection(c)

        c.addView(hairline())

        addCharacterStylesSection(c)

        c.addView(hairline())

        addKeyBehaviourSection(c)
    }

    // ── Row builders ─────────────────────────────────────────────────────

    private fun addLayoutRow(c: LinearLayout) {
        val row = settingRow()
        row.addView(makeLabel("Layout"))

        val current = KeyboardSettings.getLayout(context)
        val labels  = listOf("LigaCheh", "Arabic", "Phonetic")
        val types   = listOf(
            KeyboardSettings.LayoutType.LSD,
            KeyboardSettings.LayoutType.ARABIC_STANDARD,
            KeyboardSettings.LayoutType.CRULP_URDU)

        row.addView(segControl(labels, types.indexOf(current)) { idx ->
            val t = types[idx]
            KeyboardSettings.setLayout(context, t)
            onApplyLayer?.invoke()
        })
        c.addView(row)
    }

    private fun addToggleRow(c: LinearLayout, label: String, get: () -> Boolean, set: (Boolean) -> Unit) {
        val row = settingRow()
        row.addView(makeLabel(label))
        row.addView(Switch(context).apply {
            isChecked = get()
            setOnCheckedChangeListener { _, v -> set(v) }
        })
        c.addView(row)
    }

    private fun addDoublePressSection(c: LinearLayout) {
        val mainRow = settingRow()
        mainRow.addView(makeLabel("Double-press"))

        val sub = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }

        val windowLabels = listOf("0.25s", "0.40s", "0.60s")
        val windowValues = listOf(250L, 400L, 600L)
        val curWindow    = KeyboardSettings.getDoublePressWindowMs(context)
        val winIdx       = windowValues.indexOfFirst { it == curWindow }.coerceAtLeast(1)

        addSubRow(sub, "Window", windowLabels, false, winIdx) { idx ->
            KeyboardSettings.setDoublePressWindowMs(context, windowValues[idx])
        }

        val sw = Switch(context).apply {
            isChecked = KeyboardSettings.getDoublePressEnabled(context)
            setOnCheckedChangeListener { _, v ->
                KeyboardSettings.setDoublePressEnabled(context, v)
                sub.visibility = if (v) VISIBLE else GONE
            }
        }
        sub.visibility = if (sw.isChecked) VISIBLE else GONE
        mainRow.addView(sw)

        c.addView(mainRow)
        c.addView(sub)
        doublePressSubSection = sub
    }

    private fun addCharacterStylesSection(c: LinearLayout) {
        addSubRow(c, "Double ا",     listOf("اٰ", "آ"), true,
            if (KeyboardSettings.getDoubleAlefStyle(context) == KeyboardSettings.DoubleAlefStyle.KHARO_ZABAR) 0 else 1
        ) { idx ->
            KeyboardSettings.setDoubleAlefStyle(context,
                if (idx == 0) KeyboardSettings.DoubleAlefStyle.KHARO_ZABAR
                else          KeyboardSettings.DoubleAlefStyle.ALEF_MADDA)
        }
        addSubRow(c, "Yeh",          listOf("ي", "ی"), true,
            if (KeyboardSettings.getYehStyle(context) == KeyboardSettings.YehStyle.ARABIC_YEH) 0 else 1
        ) { idx ->
            KeyboardSettings.setYehStyle(context,
                if (idx == 0) KeyboardSettings.YehStyle.ARABIC_YEH
                else          KeyboardSettings.YehStyle.FARSI_YEH)
            onApplyLayer?.invoke()
        }
        addSubRow(c, "Kaaf",         listOf("ك", "ک"), true,
            if (KeyboardSettings.getKaafStyle(context) == KeyboardSettings.KaafStyle.ARABIC_KAAF) 0 else 1
        ) { idx ->
            KeyboardSettings.setKaafStyle(context,
                if (idx == 0) KeyboardSettings.KaafStyle.ARABIC_KAAF
                else          KeyboardSettings.KaafStyle.URDU_KAAF)
            onApplyLayer?.invoke()
        }
        addSubRow(c, "Haa",          listOf("ه", "ہ"), true,
            if (KeyboardSettings.getHaaStyle(context) == KeyboardSettings.HaaStyle.ARABIC_HAA) 0 else 1
        ) { idx ->
            KeyboardSettings.setHaaStyle(context,
                if (idx == 0) KeyboardSettings.HaaStyle.ARABIC_HAA
                else          KeyboardSettings.HaaStyle.URDU_HAA)
            onApplyLayer?.invoke()
        }
        addSubRow(c, "Taa marbuta",  listOf("ة", "ۃ"), true,
            if (KeyboardSettings.getTaaMarbuta(context) == KeyboardSettings.TaaMarbuta.ARABIC_TAA) 0 else 1
        ) { idx ->
            KeyboardSettings.setTaaMarbuta(context,
                if (idx == 0) KeyboardSettings.TaaMarbuta.ARABIC_TAA
                else          KeyboardSettings.TaaMarbuta.URDU_TAA)
            onApplyLayer?.invoke()
        }
    }

    private fun addKeyBehaviourSection(c: LinearLayout) {
        val delayLabels = listOf("Short", "Normal", "Long")
        val delayValues = listOf(200L, 350L, 500L)
        val curDelay    = KeyboardSettings.getLongPressDelayMs(context)
        val delayIdx    = delayValues.indexOfFirst { it == curDelay }.coerceAtLeast(1)

        addSubRow(c, "Long-press", delayLabels, false, delayIdx) { idx ->
            KeyboardSettings.setLongPressDelayMs(context, delayValues[idx])
        }

        val repeatLabels = listOf("Off", "Slow", "Fast")
        val repeatValues = listOf(0L, 250L, 100L)
        val curRepeat    = KeyboardSettings.getPopupRepeatIntervalMs(context)
        val repeatIdx    = repeatValues.indexOfFirst { it == curRepeat }.coerceAtLeast(2)

        addSubRow(c, "Repeat", repeatLabels, false, repeatIdx) { idx ->
            KeyboardSettings.setPopupRepeatIntervalMs(context, repeatValues[idx])
        }
    }

    /** Builds an indented sub-row with a thin separator above it. Returns the wrapper view. */
    private fun addSubRow(
        parent: LinearLayout,
        label: String,
        items: List<String>,
        useArabicFont: Boolean,
        current: Int,
        onSelect: (Int) -> Unit
    ): View {
        val font = if (useArabicFont)
            runCatching { resources.getFont(R.font.fatemi_maqala_regular) }.getOrNull()
        else null

        val wrapper = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        wrapper.addView(hairline().also { it.alpha = 0.4f })

        val row = settingRow().also { it.setPadding(dp(12), 0, 0, 0) }
        row.addView(makeSubLabel(label))
        row.addView(segControl(items, current, font = font, onSelect = onSelect))
        wrapper.addView(row)

        parent.addView(wrapper)
        return wrapper
    }

    // ── Segmented control ─────────────────────────────────────────────────

    private fun segControl(
        items: List<String>,
        selectedIndex: Int,
        font: Typeface? = null,
        onSelect: (Int) -> Unit
    ): LinearLayout {
        var sel = selectedIndex
        val buttons = mutableListOf<TextView>()

        fun refresh() {
            for ((i, b) in buttons.withIndex()) {
                b.background = if (i == sel) GradientDrawable().apply {
                    setColor(Color.parseColor("#007AFF")); cornerRadius = dp(5f)
                } else null
                b.setTextColor(if (i == sel) Color.WHITE else KeyboardColors.keyLabel(context))
            }
        }

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            background  = GradientDrawable().apply {
                setColor(KeyboardColors.specialKey(context)); cornerRadius = dp(6f)
            }
            setPadding(dp(2), dp(2), dp(2), dp(2))
        }

        for ((i, text) in items.withIndex()) {
            val b = TextView(context).apply {
                this.text = text
                textSize  = if (font != null) 15f else 12f
                typeface  = font ?: Typeface.DEFAULT
                gravity   = Gravity.CENTER
                isClickable = true; isFocusable = true
                setPadding(dp(10), dp(4), dp(10), dp(4))
                setOnClickListener { sel = i; refresh(); onSelect(i) }
            }
            buttons.add(b)
            container.addView(b, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT))
        }
        refresh()
        return container
    }

    // ── Dismiss ───────────────────────────────────────────────────────────

    fun dismiss() {
        animate().translationY(height.toFloat()).setDuration(180).withEndAction {
            (parent as? android.view.ViewGroup)?.removeView(this)
            onApplyLayer?.invoke()
        }.start()
    }

    // ── Small helpers ─────────────────────────────────────────────────────

    private fun settingRow() = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity     = Gravity.CENTER_VERTICAL
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, dp(44))
    }

    private fun makeLabel(text: String) = TextView(context).apply {
        this.text = text
        textSize  = 14f
        setTextColor(KeyboardColors.keyLabel(context))
        layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
    }

    private fun makeSubLabel(text: String) = TextView(context).apply {
        this.text = text
        textSize  = 13f
        val base = KeyboardColors.keyLabel(context)
        setTextColor(Color.argb(180, Color.red(base), Color.green(base), Color.blue(base)))
        layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
    }

    private fun hairline() = View(context).apply {
        setBackgroundColor(KeyboardColors.separator(context))
        layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 1)
    }

    private fun dp(v: Int)   = (v * resources.displayMetrics.density).toInt()
    private fun dp(v: Float) = v * resources.displayMetrics.density
}
