package com.exordiumnetworks.ligacheh

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.text.SpannableString
import android.text.TextUtils
import android.text.style.ForegroundColorSpan
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

interface PredictiveBarDelegate {
    fun predictiveBarDidSelect(suggestion: String)
    fun predictiveBarSettingsTapped()
    fun predictiveBarBiDiTapped(issue: BiDiAnalyzer.Issue)
}

// Three-suggestion strip with a BiDi fix button and a gear button.
// The BiDi button is hidden until mixed-script text is detected.
class PredictiveBar(context: Context) : LinearLayout(context) {

    companion object {
        fun heightPx(context: Context) = (44 * context.resources.displayMetrics.density).toInt()
        private const val SETTINGS_W_DP = 40
        private const val BIDI_W_DP     = 52
    }

    var delegate: PredictiveBarDelegate? = null

    private val buttons       = mutableListOf<TextView>()
    private val biDiFixView   = BiDiFixView(context)
    private var biDiSeparator: View? = null
    private var currentIssue: BiDiAnalyzer.Issue? = null
    private var lastSuggestions: List<String> = emptyList()

    // Overlay label shown the first time the BiDi button appears
    private val tooltipLabel = TextView(context).apply {
        gravity    = Gravity.CENTER
        textSize   = 13f
        isSingleLine = true
        visibility = GONE
        setTextColor(KeyboardColors.keyLabel(context))
    }

    init {
        orientation = HORIZONTAL
        setBackgroundColor(KeyboardColors.predictiveBar(context))
        buildSuggestions()
        buildBiDiButton()
        buildGearButton()
    }

    // ── Public ────────────────────────────────────────────────────────────

    fun update(suggestions: List<String>) {
        lastSuggestions = suggestions
        if (tooltipLabel.visibility == View.VISIBLE) return
        for ((i, btn) in buttons.withIndex()) {
            val text = if (i < suggestions.size) suggestions[i] else ""
            btn.text  = text
            btn.alpha = if (text.isEmpty()) 0.35f else 1f
        }
    }

    fun showBriefMessage(msg: String, durationMs: Long = 2000) {
        tooltipLabel.text       = msg
        tooltipLabel.setTextColor(KeyboardColors.keyLabel(context))
        tooltipLabel.visibility = VISIBLE
        tooltipLabel.alpha      = 0f
        tooltipLabel.animate().alpha(1f).setDuration(150).start()
        tooltipLabel.removeCallbacks(null)
        tooltipLabel.postDelayed({
            tooltipLabel.animate().alpha(0f).setDuration(200).withEndAction {
                tooltipLabel.visibility = GONE
            }.start()
        }, durationMs)
    }

    fun updateBiDi(text: String) {
        val issue = BiDiAnalyzer.analyze(text)
        val wasNull = currentIssue == null
        currentIssue = issue
        biDiFixView.setIssue(issue)
        biDiSeparator?.visibility = if (issue != null) VISIBLE else GONE

        if (issue != null && wasNull && !KeyboardSettings.getBiDiTooltipShown(context)) {
            KeyboardSettings.setBiDiTooltipShown(context)
            showFirstRunTooltip()
        }
    }

    // ── Build ─────────────────────────────────────────────────────────────

    private fun buildSuggestions() {
        // Wrap suggestions + tooltip overlay in a FrameLayout so the tooltip
        // can float over the suggestion buttons without restructuring the bar.
        val suggestionsRow = LinearLayout(context).apply { orientation = HORIZONTAL }
        val wrapper = FrameLayout(context)

        for (i in 0 until 3) {
            val btn = TextView(context).apply {
                gravity       = Gravity.CENTER
                setTextColor(KeyboardColors.keyLabel(context))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                isSingleLine  = true
                ellipsize     = TextUtils.TruncateAt.END
                if (i == 1) setTypeface(null, Typeface.BOLD)
                alpha = 0.35f
                setPadding(dp(8), 0, dp(8), 0)
                setOnClickListener {
                    val t = text?.toString()
                    if (!t.isNullOrEmpty()) delegate?.predictiveBarDidSelect(t)
                }
                layoutParams = LayoutParams(0, LayoutParams.MATCH_PARENT, 1f)
            }
            suggestionsRow.addView(btn)
            buttons.add(btn)
            if (i < 2) suggestionsRow.addView(separatorView())
        }
        update(emptyList())

        wrapper.addView(suggestionsRow,
            FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
        wrapper.addView(tooltipLabel,
            FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))

        addView(wrapper, LayoutParams(0, LayoutParams.MATCH_PARENT, 1f))
    }

    private fun buildBiDiButton() {
        biDiSeparator = separatorView().also {
            it.visibility = GONE
            addView(it)
        }
        biDiFixView.apply {
            layoutParams = LayoutParams(dp(BIDI_W_DP), LayoutParams.MATCH_PARENT)
            onTap = { currentIssue?.let { delegate?.predictiveBarBiDiTapped(it) } }
        }
        addView(biDiFixView)
    }

    private fun buildGearButton() {
        addView(separatorView())
        addView(TextView(context).apply {
            text      = "⚙"
            textSize  = 16f
            gravity   = Gravity.CENTER
            setTextColor(KeyboardColors.keyLabel(context))
            alpha     = 0.55f
            isClickable = true
            isFocusable = true
            setOnClickListener { delegate?.predictiveBarSettingsTapped() }
            layoutParams = LayoutParams(dp(SETTINGS_W_DP), LayoutParams.MATCH_PARENT)
        })
    }

    // ── First-run tooltip ─────────────────────────────────────────────────

    private fun showFirstRunTooltip() {
        val accent  = Color.parseColor("#007AFF")
        val label   = KeyboardColors.keyLabel(context)
        val message = "Tap  اA  to fix mixed text"
        val span    = SpannableString(message)
        // Colour the اA characters blue
        val start = message.indexOf("اA")
        if (start >= 0) span.setSpan(ForegroundColorSpan(accent), start, start + 2, 0)
        tooltipLabel.text       = span
        tooltipLabel.setTextColor(label)
        tooltipLabel.visibility = VISIBLE
        tooltipLabel.alpha      = 0f
        tooltipLabel.animate().alpha(1f).setDuration(250).start()

        postDelayed({
            tooltipLabel.animate().alpha(0f).setDuration(250).withEndAction {
                tooltipLabel.visibility = GONE
                update(lastSuggestions)
            }.start()
        }, 3500)
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private fun separatorView() = View(context).apply {
        setBackgroundColor(KeyboardColors.separator(context))
        layoutParams = LayoutParams(1, LayoutParams.MATCH_PARENT).apply {
            topMargin    = dp(8)
            bottomMargin = dp(8)
        }
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}
