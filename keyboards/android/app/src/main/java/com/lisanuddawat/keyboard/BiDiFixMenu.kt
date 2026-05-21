package com.lisanuddawat.keyboard

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.inputmethod.InputConnection
import android.widget.*

// Popup panel shown when the BiDi fix button is tapped.
// Offers a smart one-tap Fix plus three manual options.
class BiDiFixMenu(context: Context) : FrameLayout(context) {

    companion object {
        fun show(
            parent: FrameLayout,
            issue: BiDiAnalyzer.Issue?,
            getIc: () -> InputConnection?,
            onDismiss: () -> Unit
        ): BiDiFixMenu {
            val menu = BiDiFixMenu(parent.context)
            menu.currentIssue = issue
            menu.getIc        = getIc
            menu.onDismiss    = onDismiss
            parent.addView(menu, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
            val startY = parent.height.toFloat().coerceAtLeast(300f)
            menu.translationY = startY
            parent.post { menu.animate().translationY(0f).setDuration(200).start() }
            return menu
        }
    }

    private var currentIssue: BiDiAnalyzer.Issue? = null
    private var getIc: (() -> InputConnection?)? = null
    private var onDismiss: (() -> Unit)? = null

    init { buildUi() }

    private fun buildUi() {
        // Transparent top area dismisses on tap
        setOnClickListener { dismiss() }
        setBackgroundColor(Color.TRANSPARENT)

        val panel = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(KeyboardColors.background(context))
            setOnClickListener { /* consume — don't dismiss */ }
        }
        val panelLp = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        panelLp.gravity = Gravity.BOTTOM
        addView(panel, panelLp)

        panel.addView(buildHeader())
        panel.addView(hairline())

        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(8), dp(16), dp(16))
        }
        panel.addView(content)

        // Prominent Fix button
        val fixBtn = TextView(context).apply {
            text      = "Fix"
            textSize  = 16f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            gravity   = Gravity.CENTER
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#007AFF"))
                cornerRadius = dp(10f)
            }
            isClickable = true; isFocusable = true
            setOnClickListener {
                val ic = getIc?.invoke() ?: return@setOnClickListener
                currentIssue?.let { BiDiAnalyzer.applySmartFix(it, ic) }
                dismiss()
            }
        }
        val fixLp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(48))
        fixLp.bottomMargin = dp(10)
        content.addView(fixBtn, fixLp)

        content.addView(hairline())
        addManualRow(content, "Fix whole message",
            "Adds a direction mark at the very start") {
            getIc?.invoke()?.let { BiDiAnalyzer.insertRlmAtStart(it) }
            dismiss()
        }
        content.addView(hairline())
        addManualRow(content, "Fix at cursor",
            "Adds a direction mark at the cursor") {
            getIc?.invoke()?.let { BiDiAnalyzer.insertRlmAtCursor(it) }
            dismiss()
        }
        content.addView(hairline())
        addManualRow(content, "Mark selection as left-to-right",
            "Isolates the selected text in LTR") {
            getIc?.invoke()?.let { BiDiAnalyzer.wrapSelectionAsLtr(it) }
            dismiss()
        }
    }

    private fun buildHeader(): View {
        val bar = FrameLayout(context).apply {
            setBackgroundColor(KeyboardColors.predictiveBar(context))
        }
        bar.addView(TextView(context).apply {
            text      = "Fix Text Direction"
            textSize  = 14f
            setTypeface(null, Typeface.BOLD)
            setTextColor(KeyboardColors.keyLabel(context))
            gravity   = Gravity.CENTER
        }, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, dp(44)))
        bar.addView(TextView(context).apply {
            text      = "Done"
            textSize  = 14f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.parseColor("#007AFF"))
            setPadding(0, 0, dp(14), 0)
            gravity   = Gravity.CENTER_VERTICAL or Gravity.END
            isClickable = true; isFocusable = true
            setOnClickListener { dismiss() }
        }, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, dp(44)))
        return bar
    }

    private fun addManualRow(parent: LinearLayout, label: String, sub: String, action: () -> Unit) {
        val row = LinearLayout(context).apply {
            orientation  = LinearLayout.VERTICAL
            gravity      = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(52))
            isClickable  = true; isFocusable = true
            setOnClickListener { action() }
        }
        row.addView(TextView(context).apply {
            text     = label
            textSize = 14f
            setTextColor(KeyboardColors.keyLabel(context))
        })
        row.addView(TextView(context).apply {
            text     = sub
            textSize = 11f
            val base = KeyboardColors.keyLabel(context)
            setTextColor(Color.argb(140, Color.red(base), Color.green(base), Color.blue(base)))
        })
        parent.addView(row)
    }

    fun dismiss() {
        animate().translationY(height.toFloat()).setDuration(160).withEndAction {
            (parent as? android.view.ViewGroup)?.removeView(this)
            onDismiss?.invoke()
        }.start()
    }

    private fun hairline() = View(context).apply {
        setBackgroundColor(KeyboardColors.separator(context))
        layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 1)
    }

    private fun dp(v: Int)   = (v * resources.displayMetrics.density).toInt()
    private fun dp(v: Float) = v * resources.displayMetrics.density
}
