package com.lisanuddawat.keyboard

import android.content.Context
import android.graphics.Typeface
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView

interface PredictiveBarDelegate {
    fun predictiveBarDidSelect(suggestion: String)
    fun predictiveBarSettingsTapped()
}

// Three-suggestion strip with a gear button that opens the settings panel.
class PredictiveBar(context: Context) : LinearLayout(context) {

    companion object {
        fun heightPx(context: Context) = (44 * context.resources.displayMetrics.density).toInt()
        private const val SETTINGS_W_DP = 40
    }

    var delegate: PredictiveBarDelegate? = null
    private val buttons = mutableListOf<TextView>()

    init {
        orientation = HORIZONTAL
        setBackgroundColor(KeyboardColors.predictiveBar(context))
        buildSuggestions()
        buildGearButton()
    }

    fun update(suggestions: List<String>) {
        for ((i, btn) in buttons.withIndex()) {
            val text = if (i < suggestions.size) suggestions[i] else ""
            btn.text  = text
            btn.alpha = if (text.isEmpty()) 0.35f else 1f
        }
    }

    private fun buildSuggestions() {
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
            addView(btn)
            buttons.add(btn)

            if (i < 2) addView(separatorView())
        }
        update(emptyList())
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

    private fun separatorView() = View(context).apply {
        setBackgroundColor(KeyboardColors.separator(context))
        layoutParams = LayoutParams(1, LayoutParams.MATCH_PARENT).apply {
            topMargin    = dp(8)
            bottomMargin = dp(8)
        }
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}
