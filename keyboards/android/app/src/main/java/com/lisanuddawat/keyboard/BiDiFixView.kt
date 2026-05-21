package com.lisanuddawat.keyboard

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.view.View

// Animated button shown in the predictive bar when mixed-script text is detected.
// Renders a mini before→after of the specific BiDi issue: the LTR fragment slides
// from the wrong side to the correct side, then the animation loops.
class BiDiFixView(context: Context) : View(context) {

    private val rtlPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.LEFT }
    private val ltrPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.LEFT }

    private var rtlStr = "ع"
    private var ltrStr = "123"

    // 0 = broken state, 1 = fixed state
    private var animPhase = 0f

    private val animator = ValueAnimator.ofFloat(0f, 1f).apply {
        duration = 3200L
        repeatCount = ValueAnimator.INFINITE
        addUpdateListener { anim ->
            val r = anim.animatedValue as Float
            // 0–25 %: slide to fixed; 25–65 %: hold fixed; 65–80 %: slide back; 80–100 %: hold broken
            animPhase = when {
                r < 0.25f -> r / 0.25f
                r < 0.65f -> 1f
                r < 0.80f -> 1f - (r - 0.65f) / 0.15f
                else      -> 0f
            }
            invalidate()
        }
    }

    var onTap: (() -> Unit)? = null

    init {
        val size = dp(12f)
        rtlPaint.textSize = size
        ltrPaint.textSize = size * 0.9f

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            runCatching { resources.getFont(R.font.fatemi_maqala_regular) }.getOrNull()
                ?.let { rtlPaint.typeface = it }
        }

        isClickable = true
        isFocusable = true
        setOnClickListener { onTap?.invoke() }
        visibility = GONE
    }

    fun setIssue(issue: BiDiAnalyzer.Issue?) {
        if (issue != null) {
            rtlStr = issue.previewRtl
            ltrStr = issue.previewLtr
            if (visibility != VISIBLE) {
                visibility = VISIBLE
                animator.start()
            }
        } else {
            visibility = GONE
            animator.cancel()
            animPhase = 0f
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        animator.cancel()
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()

        val t = smoothStep(animPhase)
        updateColors(t)

        val rtlW    = rtlPaint.measureText(rtlStr)
        val ltrW    = ltrPaint.measureText(ltrStr)
        val gap     = dp(2.5f)
        val totalW  = rtlW + ltrW + gap
        val originX = (w - totalW) / 2f
        val baseline = h * 0.63f

        // Broken state: [ltr] [gap] [rtl]   →   Fixed: [rtl] [gap] [ltr]
        val ltrX = lerp(originX,             originX + rtlW + gap, t)
        val rtlX = lerp(originX + ltrW + gap, originX,             t)

        canvas.drawText(ltrStr, ltrX, baseline, ltrPaint)
        canvas.drawText(rtlStr, rtlX, baseline, rtlPaint)
    }

    private fun updateColors(t: Float) {
        val label  = KeyboardColors.keyLabel(context)
        val accent = Color.parseColor("#007AFF")
        val dim    = Color.argb(160, Color.red(label), Color.green(label), Color.blue(label))
        rtlPaint.color = lerpColor(label, accent, t)
        ltrPaint.color = lerpColor(dim,   accent, t)
    }

    private fun smoothStep(x: Float): Float {
        val t = x.coerceIn(0f, 1f)
        return t * t * (3f - 2f * t)
    }

    private fun lerp(a: Float, b: Float, t: Float) = a + (b - a) * t

    private fun lerpColor(from: Int, to: Int, t: Float): Int {
        fun ch(f: Int, s: Int) = (f + (s - f) * t).toInt().coerceIn(0, 255)
        return Color.argb(
            ch(Color.alpha(from), Color.alpha(to)),
            ch(Color.red(from),   Color.red(to)),
            ch(Color.green(from), Color.green(to)),
            ch(Color.blue(from),  Color.blue(to))
        )
    }

    private fun dp(v: Float) = v * resources.displayMetrics.density
}
