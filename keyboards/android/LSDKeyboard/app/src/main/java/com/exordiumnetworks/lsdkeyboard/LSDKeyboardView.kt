package com.exordiumnetworks.lsdkeyboard

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import kotlin.math.max

// Canvas-based keyboard view. Architecture mirrors iOS KeyboardView:
//   - All touch logic is centralised here (cross-key sliding works for free).
//   - Double-tap state machine: 350 ms window, same logic as iOS/macOS.
//   - Backspace acceleration: char-by-char for first 10 fires, then word-by-word.

class LSDKeyboardView(context: Context) : View(context) {

    init {
        ViewCompat.setOnApplyWindowInsetsListener(this) { _, insets ->
            val nav = insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom
            if (nav != navBarH) { navBarH = nav; requestLayout() }
            insets
        }
    }

    // -------------------------------------------------------------------------
    // Public interface

    interface KeyListener {
        fun onKeyPressed(key: KeyData)
        fun onDoubleTap(key: KeyData)
        fun onBackspaceWord()
        fun onLongPressAlternate(char: String)
    }

    var listener: KeyListener? = null

    fun setLayer(layer: KeyboardLayer) {
        currentLayer = layer
        computeLayout(width, height)
        invalidate()
    }

    // -------------------------------------------------------------------------
    // Layout constants (dp converted to px in init)

    private val density = context.resources.displayMetrics.density

    private val keyH       = 46f * density
    private val rowSp      = 12f * density
    private val keySp      =  6f * density
    private val sidePad    =  3f * density
    private val topPad     = 12f * density
    private val btmPad     =  5f * density
    private val cornerR    =  8f * density
    private val keyTextSz  = 20f * density
    private val secTextSz  =  9f * density

    // -------------------------------------------------------------------------
    // State

    private var currentLayer: KeyboardLayer = KeyboardLayoutData.defaultLayer

    // Pre-computed key rectangles rebuilt on every layout pass.
    private data class KeyRect(val key: KeyData, val rect: RectF)

    private var keyRects = listOf<KeyRect>()

    // Touch tracking
    private var activeKey: KeyRect? = null

    // Double-tap tracking (mirrors iOS logic)
    private var lastTappedPrimary: String? = null
    private var lastTapTime = 0L
    private val DOUBLE_TAP_MS = 350L

    // Navigation bar inset — updated via WindowInsets, extends the view height so
    // keys stay above the gesture/button bar without being clipped.
    private var navBarH = 0

    // Backspace acceleration
    private val handler = Handler(Looper.getMainLooper())
    private var bspRunnable: Runnable? = null
    private var bspCount = 0

    // -------------------------------------------------------------------------
    // Paints

    private val charKeyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#3A3A3C")
    }
    private val specialKeyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#545456")
    }
    private val activeKeyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#636366")
    }
    private val primaryTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = keyTextSz
        textAlign = Paint.Align.CENTER
    }
    private val secondaryTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#8E8E93")
        textSize = secTextSz
        textAlign = Paint.Align.RIGHT
    }
    private val bgPaint = Paint().apply {
        color = Color.parseColor("#1C1C1E")
    }

    // -------------------------------------------------------------------------
    // Measure & layout

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = MeasureSpec.getSize(widthMeasureSpec)
        val rows = currentLayer.rows.size
        val h = (topPad + rows * keyH + max(0, rows - 1) * rowSp + btmPad + navBarH).toInt()
        setMeasuredDimension(w, h)
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        ViewCompat.requestApplyInsets(this)
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        computeLayout(w, h)
    }

    private fun computeLayout(w: Int, @Suppress("UNUSED_PARAMETER") h: Int) {
        if (w == 0) return
        val result = mutableListOf<KeyRect>()
        val availW = w - sidePad * 2
        var y = topPad

        for (row in currentLayer.rows) {
            val stdW = standardKeyWidth(row, availW)
            val rawWidths = row.map { key ->
                when (val kw = key.width) {
                    KeyWidth.Standard  -> stdW
                    KeyWidth.Wide      -> stdW * 1.5f
                    KeyWidth.ExtraWide -> stdW * 2.5f
                    KeyWidth.Flexible  -> 0f
                    is KeyWidth.Fixed  -> kw.dp * density
                }
            }
            val fixedTotal = rawWidths.sum() + keySp * (row.size - 1)
            val flexCount = rawWidths.count { it == 0f }
            val flexW = if (flexCount > 0) (availW - fixedTotal) / flexCount else 0f
            val widths = rawWidths.map { if (it == 0f) flexW else it }

            var x = sidePad
            for ((key, kw) in row.zip(widths)) {
                result += KeyRect(key, RectF(x, y, x + kw, y + keyH))
                x += kw + keySp
            }
            y += keyH + rowSp
        }
        keyRects = result
    }

    private fun standardKeyWidth(row: List<KeyData>, availW: Float): Float {
        var slots = 0f
        var fixedUsed = 0f
        for (key in row) {
            when (val kw = key.width) {
                KeyWidth.Standard  -> slots += 1f
                KeyWidth.Wide      -> slots += 1.5f
                KeyWidth.ExtraWide -> slots += 2.5f
                KeyWidth.Flexible  -> Unit
                is KeyWidth.Fixed  -> fixedUsed += kw.dp * density
            }
        }
        val totalSpacing = keySp * (row.size - 1)
        return if (slots > 0) (availW - fixedUsed - totalSpacing) / slots else 44f * density
    }

    // -------------------------------------------------------------------------
    // Drawing

    override fun onDraw(canvas: Canvas) {
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)
        for (kr in keyRects) {
            drawKey(canvas, kr)
        }
    }

    private fun drawKey(canvas: Canvas, kr: KeyRect) {
        val isActive = kr === activeKey
        val isSpecial = kr.key.type != KeyType.CHARACTER

        val bgPaint = when {
            isActive  -> activeKeyPaint
            isSpecial -> specialKeyPaint
            else      -> charKeyPaint
        }
        canvas.drawRoundRect(kr.rect, cornerR, cornerR, bgPaint)

        // Primary label — vertically centred in key
        val fm = primaryTextPaint.fontMetrics
        val textY = kr.rect.centerY() - (fm.ascent + fm.descent) / 2
        canvas.drawText(kr.key.primary, kr.rect.centerX(), textY, primaryTextPaint)

        // Secondary label — top-right corner (small)
        if (kr.key.secondary.isNotEmpty()) {
            val sx = kr.rect.right - 3f * density
            val sy = kr.rect.top + secTextSz + 2f * density
            canvas.drawText(kr.key.secondary, sx, sy, secondaryTextPaint)
        }
    }

    // -------------------------------------------------------------------------
    // Touch handling

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                val kr = keyAt(event.x, event.y) ?: return true
                activeKey = kr
                invalidate()
                if (kr.key.type == KeyType.BACKSPACE) startBackspaceRepeat()
            }
            MotionEvent.ACTION_MOVE -> {
                val kr = keyAt(event.x, event.y)
                if (kr !== activeKey) {
                    if (activeKey?.key?.type == KeyType.BACKSPACE) stopBackspaceRepeat()
                    activeKey = kr
                    invalidate()
                    if (kr?.key?.type == KeyType.BACKSPACE) startBackspaceRepeat()
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                stopBackspaceRepeat()
                val kr = activeKey ?: run { activeKey = null; return true }
                activeKey = null
                invalidate()
                fireKey(kr)
            }
        }
        return true
    }

    private fun fireKey(kr: KeyRect) {
        val key = kr.key
        val now = System.currentTimeMillis()

        val isDouble = key.type == KeyType.CHARACTER
            && key.secondary.isNotEmpty()
            && key.primary == lastTappedPrimary
            && (now - lastTapTime) < DOUBLE_TAP_MS

        if (isDouble) {
            lastTappedPrimary = null
            lastTapTime = 0L
            listener?.onDoubleTap(key)
        } else {
            lastTappedPrimary = if (key.type == KeyType.CHARACTER) key.primary else null
            lastTapTime = if (key.type == KeyType.CHARACTER) now else 0L
            listener?.onKeyPressed(key)
        }
    }

    // -------------------------------------------------------------------------
    // Hit testing — mirrors iOS two-phase algorithm

    private fun keyAt(x: Float, y: Float): KeyRect? {
        // Phase 1: direct hit (3px inset tolerance)
        val inset = 3f * density
        keyRects.firstOrNull { kr ->
            x >= kr.rect.left - inset && x <= kr.rect.right + inset &&
            y >= kr.rect.top - inset  && y <= kr.rect.bottom + inset
        }?.let { return it }

        // Phase 2: nearest-centre, vertical distance compressed 0.6×
        var best: KeyRect? = null
        var bestDist = Float.MAX_VALUE
        for (kr in keyRects) {
            val dx = x - kr.rect.centerX()
            val dy = (y - kr.rect.centerY()) * 0.6f
            val d = dx * dx + dy * dy
            if (d < bestDist) { bestDist = d; best = kr }
        }
        return best
    }

    // -------------------------------------------------------------------------
    // Backspace acceleration
    // Phase 1 (0–10 fires at 75 ms): char-by-char  via onKeyPressed
    // Phase 2 (10+ fires at 350 ms): word-by-word  via onBackspaceWord

    private fun startBackspaceRepeat() {
        bspCount = 0
        val runnable = object : Runnable {
            override fun run() {
                val kr = activeKey ?: return
                bspCount++
                if (bspCount <= 10) {
                    listener?.onKeyPressed(kr.key)
                    handler.postDelayed(this, 75)
                } else {
                    listener?.onBackspaceWord()
                    handler.postDelayed(this, 350)
                }
            }
        }
        bspRunnable = runnable
        handler.postDelayed(runnable, 500)
    }

    private fun stopBackspaceRepeat() {
        bspRunnable?.let { handler.removeCallbacks(it) }
        bspRunnable = null
        bspCount = 0
    }
}
