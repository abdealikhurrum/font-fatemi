package com.lisanuddawat.keyboard

import android.content.Context
import android.graphics.*

// Bubble that pops up above a key the instant it is pressed — mirrors the iOS callout.
// Drawn with a rounded rect + downward pointer using Canvas Path.
class KeyCalloutView(
    context: Context,
    private val character: String,
    private val bubbleWidth: Int,
    private val bubbleHeight: Int  // excludes pointer
) : android.view.View(context) {

    private val fatemiTypeface: Typeface? = runCatching {
        resources.getFont(R.font.fatemi_maqala_regular)
    }.getOrNull()

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        color = Color.WHITE
        textSize = sp(28f)
    }
    private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = KeyboardColors.calloutBubble(context)
    }

    private val pointerH = dp(8f)
    private val cornerR  = dp(8f)

    init {
        isClickable = false
        isFocusable = false
        textPaint.typeface = fatemiTypeface ?: Typeface.DEFAULT
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(bubbleWidth, bubbleHeight + pointerH.toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val w   = width.toFloat()
        val bH  = bubbleHeight.toFloat()
        val mid = w / 2f

        val path = Path()
        path.moveTo(cornerR, 0f)
        path.lineTo(w - cornerR, 0f)
        path.arcTo(RectF(w - cornerR * 2, 0f, w, cornerR * 2), -90f, 90f)
        path.lineTo(w, bH - cornerR)
        path.arcTo(RectF(w - cornerR * 2, bH - cornerR * 2, w, bH), 0f, 90f)
        // downward pointer
        path.lineTo(mid + pointerH, bH)
        path.lineTo(mid, bH + pointerH)
        path.lineTo(mid - pointerH, bH)
        path.lineTo(cornerR, bH)
        path.arcTo(RectF(0f, bH - cornerR * 2, cornerR * 2, bH), 90f, 90f)
        path.lineTo(0f, cornerR)
        path.arcTo(RectF(0f, 0f, cornerR * 2, cornerR * 2), 180f, 90f)
        path.close()

        canvas.drawPath(path, bgPaint)

        val textY = bH / 2f - (textPaint.ascent() + textPaint.descent()) / 2f
        canvas.drawText(character, mid, textY, textPaint)
    }

    private fun dp(v: Float) = (v * resources.displayMetrics.density)
    private fun sp(v: Float) = (v * resources.displayMetrics.scaledDensity)
}
