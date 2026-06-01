package com.exordiumnetworks.ligacheh

import android.content.Context
import android.graphics.*
import android.view.View
import android.widget.FrameLayout

interface LongPressPopupDelegate {
    fun popupDidSelect(character: String)
    fun popupDidCancel()
}

// Horizontal strip of alternate characters shown on long-press.
// Parent (KeyboardView) routes touch movement into updateSelection().
class LongPressPopupView(
    context: Context,
    private val alternates: List<String>,
    private val keyWidth: Int,
    private val keyHeight: Int
) : FrameLayout(context) {

    var delegate: LongPressPopupDelegate? = null

    private val padding  = dp(6f).toInt()
    private val spacing  = dp(4f).toInt()
    private val cornerR  = dp(10f)

    val totalWidth:  Int = padding * 2 + alternates.size * keyWidth + (alternates.size - 1) * spacing
    val totalHeight: Int = padding * 2 + keyHeight

    private val itemViews = mutableListOf<ItemView>()
    private var selectedIndex: Int? = null

    // Exposed so KeyboardView can schedule repeat chaining when selection changes.
    val currentSelectedCharacter: String?
        get() = selectedIndex?.let { alternates[it] }

    private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    private val fatemiTypeface: Typeface? = runCatching {
        resources.getFont(R.font.fatemi_maqala_regular)
    }.getOrNull()

    init {
        setWillNotDraw(false)
        for ((i, alt) in alternates.withIndex()) {
            val x = padding + i * (keyWidth + spacing)
            val item = ItemView(context, alt)
            val lp = LayoutParams(keyWidth, keyHeight).apply {
                leftMargin = x
                topMargin  = padding
            }
            addView(item, lp)
            itemViews.add(item)
        }
    }

    override fun onDraw(canvas: Canvas) {
        bgPaint.color = KeyboardColors.popup(context)
        canvas.drawRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), cornerR, cornerR, bgPaint)
    }

    // localX/Y are coordinates relative to this view's top-left corner.
    fun updateSelection(localX: Float, localY: Float) {
        val expanded = RectF(-dp(20f), -dp(60f), width + dp(20f), height + dp(60f))
        if (!expanded.contains(localX, localY)) { clearSelection(); return }

        for ((i, item) in itemViews.withIndex()) {
            val hit = RectF(
                item.left - dp(2f),  -dp(60f),
                item.right + dp(2f),  height + dp(60f)
            )
            if (hit.contains(localX, localY)) { select(i); return }
        }
        clearSelection()
    }

    fun confirmSelection() {
        val idx = selectedIndex
        if (idx != null) delegate?.popupDidSelect(alternates[idx])
        else             delegate?.popupDidCancel()
    }

    private fun select(index: Int) {
        if (index == selectedIndex) return
        clearSelection()
        selectedIndex = index
        itemViews[index].setSelected(true)
    }

    private fun clearSelection() {
        selectedIndex?.let { itemViews[it].setSelected(false) }
        selectedIndex = null
    }

    private fun dp(v: Float) = v * resources.displayMetrics.density

    // ------------------------------------------------------------------ inner

    inner class ItemView(context: Context, val character: String) : View(context) {

        // Invisible control characters get readable Latin labels for display.
        private val displayLabel = when (character) {
            "NBSP"  -> "NBSP"
            "‌" -> "ZWNJ"
            else       -> character
        }

        private var selected = false
        private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            // Latin labels need a smaller size to fit; Arabic/single chars use full size.
            textSize  = if (displayLabel.length > 1 && displayLabel.all { it.code < 128 })
                            sp(10f) else sp(20f)
            typeface  = if (displayLabel == character) fatemiTypeface ?: Typeface.DEFAULT
                        else Typeface.DEFAULT_BOLD
        }
        private val bgPaint2 = Paint(Paint.ANTI_ALIAS_FLAG)

        override fun setSelected(on: Boolean) { selected = on; invalidate() }

        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat(); val h = height.toFloat()
            if (selected) {
                bgPaint2.color = KeyboardColors.selectedItem()
                canvas.drawRoundRect(RectF(0f, 0f, w, h), dp(8f), dp(8f), bgPaint2)
            }
            textPaint.color = if (selected) Color.WHITE else KeyboardColors.popupText(context)
            val textY = h / 2f - (textPaint.ascent() + textPaint.descent()) / 2f
            canvas.drawText(displayLabel, w / 2f, textY, textPaint)
        }

        private fun dp(v: Float) = v * resources.displayMetrics.density
        private fun sp(v: Float) = v * resources.displayMetrics.scaledDensity
    }
}
