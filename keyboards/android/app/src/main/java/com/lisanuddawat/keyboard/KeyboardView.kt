package com.lisanuddawat.keyboard

import android.content.Context
import android.graphics.*
import android.os.*
import android.view.*
import android.widget.FrameLayout

interface KeyboardViewDelegate {
    fun keyPressed(key: KeyData)
    fun longPressAlternateSelected(character: String)
}

// Custom ViewGroup that lays out KeyButton children and owns all touch logic,
// mirroring the iOS KeyboardView cross-key sliding behaviour.
class KeyboardView(context: Context) : ViewGroup(context) {

    companion object {
        private const val ROW_SPACING_DP   = 8f
        private const val KEY_SPACING_DP   = 6f
        private const val SIDE_PADDING_DP  = 3f
        private const val TOP_PADDING_DP   = 8f
        private const val BOTTOM_PADDING_DP = 3f
        private const val STANDARD_KEY_H_DP = 42f
    }

    var delegate: KeyboardViewDelegate? = null

    // Overlay FrameLayout shared with the root input view — callouts and popups
    // are added here so they can escape KeyboardView's own clipping bounds.
    var overlayContainer: FrameLayout? = null

    private var keyButtons: MutableList<KeyButton> = mutableListOf()
    private var currentRows: List<List<KeyData>> = emptyList()

    private var activeKey: KeyButton? = null

    private val handler = Handler(Looper.getMainLooper())
    private var longPressRunnable: Runnable? = null
    private var backspaceRunnable: Runnable? = null
    private var backspaceInterval = 100L

    private var calloutView: KeyCalloutView? = null
    private var activePopup: LongPressPopupView? = null

    // Popup-repeat chaining: mirrors iOS schedulePopupRepeat().
    // After 500 ms holding on a selected alternate, repeat it every 100 ms.
    private var popupRepeatInitial: Runnable? = null
    private var popupRepeatTick: Runnable? = null

    private val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }

    init {
        setWillNotDraw(false)
        setBackgroundColor(KeyboardColors.background(context))
    }

    // ------------------------------------------------------------------  configure

    fun configure(layer: KeyboardLayer) {
        keyButtons.forEach { removeView(it) }
        keyButtons.clear()
        currentRows = layer.rows

        for (row in layer.rows) {
            for (keyData in row) {
                addView(KeyButton(context, keyData).also { keyButtons.add(it) })
            }
        }
        requestLayout()
    }

    // No shift key in current layout — kept for API compatibility.
    fun updateShiftAppearance(active: Boolean, locked: Boolean) = Unit

    // ------------------------------------------------------------------  measure / layout

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = MeasureSpec.getSize(widthMeasureSpec)
        val n = currentRows.size.toFloat()
        val h = (dp(TOP_PADDING_DP)
                + n * dp(STANDARD_KEY_H_DP)
                + maxOf(0f, n - 1f) * dp(ROW_SPACING_DP)
                + dp(BOTTOM_PADDING_DP)).toInt()
        setMeasuredDimension(w, h)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        if (keyButtons.isEmpty()) return

        val rows    = groupedRows()
        val sidePad = dp(SIDE_PADDING_DP)
        val availW  = (r - l).toFloat() - sidePad * 2f
        val keyH    = dp(STANDARD_KEY_H_DP)
        var y       = dp(TOP_PADDING_DP)

        for (row in rows) {
            layoutRow(row, y, availW, sidePad, keyH)
            y += keyH + dp(ROW_SPACING_DP)
        }
    }

    private fun layoutRow(
        row: List<KeyButton>,
        y: Float, availW: Float, sidePad: Float, keyH: Float
    ) {
        val sp   = dp(KEY_SPACING_DP)
        val stdW = standardKeyWidth(row, availW)

        val rawWidths = row.map { btn ->
            when (val w = btn.keyData.width) {
                is KeyWidth.Standard  -> stdW
                is KeyWidth.Wide      -> stdW * 1.5f
                is KeyWidth.ExtraWide -> stdW * 2.5f
                is KeyWidth.Fixed     -> dp(w.dp)
                is KeyWidth.Flexible  -> 0f
            }
        }

        val fixedTotal = rawWidths.sum() + (row.size - 1) * sp
        val flexCount  = rawWidths.count { it == 0f }.toFloat()
        val flexW      = if (flexCount > 0f) (availW - fixedTotal) / flexCount else 0f
        val widths     = rawWidths.map { if (it == 0f) flexW else it }

        var x = sidePad
        for ((btn, w) in row.zip(widths)) {
            btn.layout(x.toInt(), y.toInt(), (x + w).toInt(), (y + keyH).toInt())
            x += w + sp
        }
    }

    private fun standardKeyWidth(row: List<KeyButton>, availW: Float): Float {
        val sp = dp(KEY_SPACING_DP)
        var slots = 0f; var fixedUsed = 0f
        for (btn in row) {
            when (val w = btn.keyData.width) {
                is KeyWidth.Standard  -> slots += 1f
                is KeyWidth.Wide      -> slots += 1.5f
                is KeyWidth.ExtraWide -> slots += 2.5f
                is KeyWidth.Fixed     -> fixedUsed += dp(w.dp)
                is KeyWidth.Flexible  -> Unit
            }
        }
        val totalSpacing = (row.size - 1) * sp
        return if (slots > 0f) (availW - fixedUsed - totalSpacing) / slots else dp(44f)
    }

    // ------------------------------------------------------------------  touch

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                keyButtonAt(event.x, event.y)?.let { activateKey(it) }
            }

            MotionEvent.ACTION_MOVE -> {
                val popup = activePopup
                if (popup != null) {
                    val kbLoc = IntArray(2).also { getLocationOnScreen(it) }
                    val pxLoc = IntArray(2).also { popup.getLocationOnScreen(it) }
                    val prev = popup.currentSelectedCharacter
                    popup.updateSelection(
                        event.x + kbLoc[0] - pxLoc[0],
                        event.y + kbLoc[1] - pxLoc[1]
                    )
                    val next = popup.currentSelectedCharacter
                    if (next != prev) {
                        cancelPopupRepeat()
                        if (next != null) schedulePopupRepeat(next)
                    }
                    return true
                }

                val newKey = keyButtonAt(event.x, event.y)
                if (newKey != null && newKey !== activeKey) {
                    cancelTimers(); dismissCallout()
                    activeKey?.isKeyHighlighted = false
                    activateKey(newKey)
                }
            }

            MotionEvent.ACTION_UP -> {
                if (activePopup != null) {
                    activePopup?.confirmSelection()
                    dismissPopup()
                } else {
                    cancelTimers(); dismissCallout()
                    activeKey?.let {
                        it.isKeyHighlighted = false
                        delegate?.keyPressed(it.keyData)
                    }
                    activeKey = null
                }
            }

            MotionEvent.ACTION_CANCEL -> {
                cancelTimers(); dismissCallout(); dismissPopup()
                activeKey?.isKeyHighlighted = false
                activeKey = null
            }
        }
        return true
    }

    // ------------------------------------------------------------------  activation

    private fun activateKey(key: KeyButton) {
        activeKey = key
        key.isKeyHighlighted = true
        vibrate()

        if (key.keyData.type == KeyType.CHARACTER && key.keyData.primary.isNotEmpty()) {
            showCallout(key)
        }

        if (key.keyData.type == KeyType.BACKSPACE) {
            val initial = Runnable { startBackspaceRepeat() }
            longPressRunnable = initial
            handler.postDelayed(initial, 500)
            return
        }

        if (key.keyData.alternates.isNotEmpty()) {
            val lp = Runnable { dismissCallout(); showPopup(key) }
            longPressRunnable = lp
            handler.postDelayed(lp, 350)
            return
        }

        val lpt = key.keyData.longPressType
        if (lpt != null) {
            val lp = Runnable {
                dismissCallout()
                key.isKeyHighlighted = false
                activeKey = null
                delegate?.keyPressed(KeyData("", type = lpt))
            }
            longPressRunnable = lp
            handler.postDelayed(lp, 500)
        }
    }

    // ------------------------------------------------------------------  callout

    private fun showCallout(key: KeyButton) {
        dismissCallout()
        val overlay = overlayContainer ?: return

        val kbLoc = IntArray(2).also { getLocationOnScreen(it) }
        val ovLoc = IntArray(2).also { overlay.getLocationOnScreen(it) }

        val textPaintM = Paint(Paint.ANTI_ALIAS_FLAG).apply { textSize = sp(28f) }
        val bounds = Rect()
        textPaintM.getTextBounds(key.keyData.primary, 0, key.keyData.primary.length, bounds)
        val charW  = maxOf(dp(44f).toInt(), bounds.width() + dp(20f).toInt())
        val bubbleH = (key.height * 1.45f).toInt()
        val pointerH = dp(8f).toInt()

        val keyLeft   = key.left + kbLoc[0] - ovLoc[0]
        val keyTop    = key.top  + kbLoc[1] - ovLoc[1]
        val keyCenterX = keyLeft + key.width / 2f

        var x = (keyCenterX - charW / 2f).toInt()
        x = x.coerceIn(dp(4f).toInt(), overlay.width - charW - dp(4f).toInt())
        val y = (keyTop - bubbleH - pointerH + dp(4f)).toInt()

        val cv = KeyCalloutView(context, key.keyData.primary, charW, bubbleH)
        val lp = FrameLayout.LayoutParams(charW, bubbleH + pointerH).apply {
            leftMargin = x; topMargin = y
        }
        overlay.addView(cv, lp)
        calloutView = cv
    }

    private fun dismissCallout() {
        calloutView?.let { (it.parent as? ViewGroup)?.removeView(it) }
        calloutView = null
    }

    // ------------------------------------------------------------------  popup

    private fun showPopup(key: KeyButton) {
        dismissPopup()
        val overlay = overlayContainer ?: return

        // Cap item width so space-bar (flexible, very wide) doesn't produce an
        // enormous popup that overflows the screen — mirrors iOS min(keySize.width, 52).
        val itemWidth = minOf(key.width, dp(52f).toInt())
        val popup = LongPressPopupView(context, key.keyData.alternates, itemWidth, key.height)
        popup.delegate = object : LongPressPopupDelegate {
            override fun popupDidSelect(character: String) {
                delegate?.longPressAlternateSelected(character)
            }
            override fun popupDidCancel() {}
        }

        val kbLoc = IntArray(2).also { getLocationOnScreen(it) }
        val ovLoc = IntArray(2).also { overlay.getLocationOnScreen(it) }

        val keyLeft = key.left + kbLoc[0] - ovLoc[0]
        val keyTop  = key.top  + kbLoc[1] - ovLoc[1]

        var x = keyLeft.toFloat()
        val y = keyTop - popup.totalHeight - dp(4f)
        x = x.coerceIn(dp(4f), overlay.width - popup.totalWidth - dp(4f))

        val lp = FrameLayout.LayoutParams(popup.totalWidth, popup.totalHeight).apply {
            leftMargin = x.toInt(); topMargin = y.toInt()
        }
        overlay.addView(popup, lp)
        activePopup = popup
    }

    private fun dismissPopup() {
        cancelPopupRepeat()
        activePopup?.let { (it.parent as? ViewGroup)?.removeView(it) }
        activePopup = null
    }

    // ------------------------------------------------------------------  popup repeat (chaining)

    private fun schedulePopupRepeat(character: String) {
        val initial = Runnable {
            delegate?.longPressAlternateSelected(character)
            val tick = object : Runnable {
                override fun run() {
                    // Use live selection in case user has slid to a different alternate
                    val current = activePopup?.currentSelectedCharacter ?: return
                    delegate?.longPressAlternateSelected(current)
                    handler.postDelayed(this, 100)
                }
            }
            popupRepeatTick = tick
            handler.postDelayed(tick, 100)
        }
        popupRepeatInitial = initial
        handler.postDelayed(initial, 500)
    }

    private fun cancelPopupRepeat() {
        popupRepeatInitial?.let { handler.removeCallbacks(it) }
        popupRepeatTick?.let   { handler.removeCallbacks(it) }
        popupRepeatInitial = null
        popupRepeatTick    = null
    }

    // ------------------------------------------------------------------  backspace repeat

    private fun startBackspaceRepeat() {
        backspaceInterval = 100L
        fun schedule() {
            val r = object : Runnable {
                override fun run() {
                    val key = activeKey ?: return
                    if (key.keyData.type != KeyType.BACKSPACE) return
                    delegate?.keyPressed(key.keyData)
                    backspaceInterval = maxOf(33L, (backspaceInterval * 0.85).toLong())
                    backspaceRunnable = this
                    handler.postDelayed(this, backspaceInterval)
                }
            }
            backspaceRunnable = r
            handler.postDelayed(r, backspaceInterval)
        }
        schedule()
    }

    private fun cancelTimers() {
        longPressRunnable?.let { handler.removeCallbacks(it) }
        longPressRunnable = null
        backspaceRunnable?.let { handler.removeCallbacks(it) }
        backspaceRunnable = null
    }

    // ------------------------------------------------------------------  helpers

    private fun keyButtonAt(x: Float, y: Float): KeyButton? {
        val expand = dp(4f)
        return keyButtons.firstOrNull { btn ->
            RectF(btn.left.toFloat(), btn.top - expand,
                  btn.right.toFloat(), btn.bottom + expand).contains(x, y)
        }
    }

    private fun groupedRows(): List<List<KeyButton>> {
        val result = mutableListOf<List<KeyButton>>()
        var idx = 0
        for (row in currentRows) {
            val end = minOf(idx + row.size, keyButtons.size)
            if (idx < end) result.add(keyButtons.subList(idx, end).toList())
            idx += row.size
        }
        return result
    }

    private fun vibrate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(10)
        }
    }

    private fun dp(v: Float) = v * resources.displayMetrics.density
    private fun sp(v: Float) = v * resources.displayMetrics.scaledDensity
}
