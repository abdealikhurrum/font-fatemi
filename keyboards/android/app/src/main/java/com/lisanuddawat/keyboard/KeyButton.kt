package com.lisanuddawat.keyboard

import android.content.Context
import android.graphics.*

// Pure display component — touch handling lives in KeyboardView.
class KeyButton(context: Context, val keyData: KeyData) : android.view.View(context) {

    private val fatemiTypeface: Typeface? = runCatching {
        resources.getFont(R.font.fatemi_maqala_regular)
    }.getOrNull()

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
    }
    private val bgPaint   = Paint(Paint.ANTI_ALIAS_FLAG)
    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(71, 0, 0, 0) }
    private val badgePaint  = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(153, 140, 140, 140) }

    private val cornerR = dp(5f)

    var isKeyHighlighted = false
        set(value) { if (field != value) { field = value; invalidate() } }

    private var shiftActive = false
    private var shiftLocked = false

    fun updateShiftState(active: Boolean, locked: Boolean) {
        shiftActive = active; shiftLocked = locked; invalidate()
    }

    private fun normalBgColor() = when (keyData.type) {
        KeyType.CHARACTER, KeyType.SPACE -> KeyboardColors.characterKey(context)
        else -> KeyboardColors.specialKey(context)
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()

        val bgColor = when {
            isKeyHighlighted -> KeyboardColors.pressedKey(context)
            keyData.type == KeyType.SHIFT && shiftLocked -> KeyboardColors.shiftLockedBg(context)
            else -> normalBgColor()
        }

        // Drop shadow
        canvas.drawRoundRect(RectF(0f, dp(1f), w, h + dp(1f)), cornerR, cornerR, shadowPaint)

        // Key face
        bgPaint.color = bgColor
        canvas.drawRoundRect(RectF(0f, 0f, w, h), cornerR, cornerR, bgPaint)

        // Label
        val textColor = when {
            keyData.type == KeyType.SHIFT && shiftLocked -> KeyboardColors.shiftLockedText(context)
            else -> KeyboardColors.keyLabel(context)
        }
        textPaint.color = textColor
        when (keyData.type) {
            KeyType.CHARACTER -> {
                textPaint.typeface = fatemiTypeface ?: Typeface.DEFAULT
                textPaint.textSize = sp(20f)
            }
            KeyType.SHIFT, KeyType.BACKSPACE, KeyType.ENTER -> {
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

        // Small dot badge for keys that have long-press alternates
        if (keyData.alternates.isNotEmpty() && keyData.type == KeyType.CHARACTER) {
            canvas.drawCircle(w - dp(6f), dp(6f), dp(2f), badgePaint)
        }
    }

    private fun dp(v: Float) = v * resources.displayMetrics.density
    private fun sp(v: Float) = v * resources.displayMetrics.scaledDensity
}
