package com.exordiumnetworks.ligacheh

import android.content.Context
import android.graphics.*

// Pure display component — touch handling lives in KeyboardView.
class KeyButton(context: Context, val keyData: KeyData) : android.view.View(context) {

    private val fatemiTypeface: Typeface? = runCatching {
        resources.getFont(R.font.fatemi_maqala_regular)
    }.getOrNull()

    private val textPaint    = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }
    private val secPaint     = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.RIGHT }
    private val bgPaint      = Paint(Paint.ANTI_ALIAS_FLAG)
    private val shadowPaint  = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(71, 0, 0, 0) }
    private val badgePaint   = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(153, 140, 140, 140) }

    private val cornerR = dp(5f)

    var isKeyHighlighted = false
        set(value) { if (field != value) { field = value; invalidate() } }

    private fun normalBgColor() = when (keyData.type) {
        KeyType.CHARACTER, KeyType.SPACE -> KeyboardColors.characterKey(context)
        else -> KeyboardColors.specialKey(context)
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()

        // Drop shadow
        canvas.drawRoundRect(RectF(0f, dp(1f), w, h + dp(1f)), cornerR, cornerR, shadowPaint)

        // Key face
        bgPaint.color = if (isKeyHighlighted) KeyboardColors.pressedKey(context) else normalBgColor()
        canvas.drawRoundRect(RectF(0f, 0f, w, h), cornerR, cornerR, bgPaint)

        // Primary label
        textPaint.color = KeyboardColors.keyLabel(context)
        when (keyData.type) {
            KeyType.CHARACTER -> {
                textPaint.typeface = fatemiTypeface ?: Typeface.DEFAULT
                textPaint.textSize = sp(20f)
            }
            KeyType.BACKSPACE, KeyType.ENTER,
            KeyType.CURSOR_LEFT, KeyType.CURSOR_RIGHT -> {
                textPaint.typeface = Typeface.DEFAULT
                textPaint.textSize = sp(16f)
            }
            else -> {
                textPaint.typeface = Typeface.DEFAULT_BOLD
                textPaint.textSize = sp(13f)
            }
        }
        val textY = h / 2f - (textPaint.ascent() + textPaint.descent()) / 2f
        canvas.drawText(keyData.primary, w / 2f, textY, textPaint)

        // Secondary character hint — small label in bottom-right corner
        if (keyData.secondary.isNotEmpty() && keyData.type == KeyType.CHARACTER) {
            val baseColor = KeyboardColors.keyLabel(context)
            secPaint.color = Color.argb(
                120,
                Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor)
            )
            secPaint.typeface = fatemiTypeface ?: Typeface.DEFAULT
            secPaint.textSize = sp(9f)
            canvas.drawText(keyData.secondary, w - dp(3f), h - dp(2f) + secPaint.ascent(), secPaint)
        }

        // Dot badge for long-press alternates
        if (keyData.alternates.isNotEmpty() && keyData.type == KeyType.CHARACTER) {
            canvas.drawCircle(w - dp(6f), dp(6f), dp(2f), badgePaint)
        }
    }

    private fun dp(v: Float) = v * resources.displayMetrics.density
    private fun sp(v: Float) = v * resources.displayMetrics.scaledDensity
}
