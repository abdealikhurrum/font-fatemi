package com.exordiumnetworks.ligacheh

import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.SystemClock
import android.view.KeyEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class LsdKeyboardService : InputMethodService() {

    private enum class Layer { DEFAULT, NUMERIC, DIACRITIC, LATIN }

    private var currentLayer = Layer.DEFAULT
        set(value) { field = value; applyLayer() }

    private var latinShifted  = false
    private var latinCapsLock = false
    private var lastShiftTime = 0L
    private var priorToModal  = Layer.DEFAULT

    private var keyboardView: KeyboardView? = null
    private var predictiveBar: PredictiveBar? = null
    private var menuView: KeyboardMenuView? = null
    private var biDiMenu: BiDiFixMenu? = null

    // Double-space tracking (for period insertion)
    private var lastInsertedChar: Char? = null
    private var lastInsertTime: Long = 0
    private val doubleSpaceWindowMs = 400L

    // Double-press tracking (for secondary character)
    private var lastPressedPrimary: String? = null
    private var lastKeyPressTime: Long = 0

    // Set while ۚ was just auto-inserted; cleared on the next keystroke or backspace.
    private var jeemRevertPending = false

    // ── Lifecycle ────────────────────────────────────────────────────────

    override fun onCreateInputView(): View {
        val root = FrameLayout(this)
        // Fill the area behind the keys (incl. the strip above the nav bar) with the
        // keyboard background so the inset padding below looks intentional.
        root.setBackgroundColor(KeyboardColors.background(this))
        // Targeting API 35 makes the app edge-to-edge, so the IME window now extends
        // under the system navigation bar. Consume the nav-bar inset and pad the bottom
        // by it, so the keyboard always sits a consistent distance ABOVE the nav bar
        // (never flush in the gesture zone, never hidden behind the 3-button bar).
        // On API ≤34 the system already insets the IME window, so this reports 0 — no-op.
        ViewCompat.setOnApplyWindowInsetsListener(root) { v, insets ->
            val navBottom = insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom
            v.setPadding(v.paddingLeft, v.paddingTop, v.paddingRight, navBottom)
            insets
        }

        val content = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.addView(content, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ))

        val bar = PredictiveBar(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                PredictiveBar.heightPx(this@LsdKeyboardService)
            )
            delegate = object : PredictiveBarDelegate {
                override fun predictiveBarDidSelect(suggestion: String) { insertSuggestion(suggestion) }
                override fun predictiveBarSettingsTapped() { showMenu(root) }
                override fun predictiveBarBiDiTapped(issue: BiDiAnalyzer.Issue) { showBiDiMenu(root, issue) }
            }
        }
        predictiveBar = bar
        content.addView(bar)

        val kb = KeyboardView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            delegate = object : KeyboardViewDelegate {
                override fun keyPressed(key: KeyData) { handleKey(key) }
                override fun longPressAlternateSelected(character: String) { insert(character) }
            }
            overlayContainer = root
        }
        keyboardView = kb
        content.addView(kb)

        currentLayer = Layer.DEFAULT
        return root
    }

    // ── Layer ─────────────────────────────────────────────────────────────

    private fun applyLayer() {
        // The numeric/diacritic "return to letters" key reflects where it will go:
        // "ABC" if it came from (and returns to) Latin, otherwise Arabic "ا ب ج".
        val modalBackLabel = if (priorToModal == Layer.LATIN) "ABC" else "ا ب ج"
        val layer = when (currentLayer) {
            Layer.DEFAULT -> when (KeyboardSettings.getLayout(this)) {
                KeyboardSettings.LayoutType.LSD            -> KeyboardLayoutData.defaultLayer(this)
                KeyboardSettings.LayoutType.ARABIC_STANDARD -> ArabicStandardLayoutData.defaultLayer(this)
                KeyboardSettings.LayoutType.CRULP_URDU      -> CRULPUrduLayoutData.defaultLayer(this)
            }
            Layer.NUMERIC   -> KeyboardLayoutData.numericLayer(modalBackLabel)
            Layer.DIACRITIC -> KeyboardLayoutData.diacriticLayer(modalBackLabel)
            Layer.LATIN     -> if (latinShifted) LatinLayoutData.upperLayer
                               else              LatinLayoutData.lowerLayer
        }
        keyboardView?.configure(layer)
    }

    // ── Settings menu ─────────────────────────────────────────────────────

    private fun showMenu(root: FrameLayout) {
        if (menuView != null) return
        menuView = KeyboardMenuView.show(root) {
            menuView = null
            if (currentLayer == Layer.DEFAULT) applyLayer()
        }
    }

    // ── BiDi fix menu ─────────────────────────────────────────────────────

    private fun showBiDiMenu(root: FrameLayout, issue: BiDiAnalyzer.Issue) {
        if (biDiMenu != null) return
        biDiMenu = BiDiFixMenu.show(
            root, issue,
            getIc        = { currentInputConnection },
            onFixApplied = { predictiveBar?.showBriefMessage("Direction mark added  ·  backspace to undo") },
            onDismiss    = { biDiMenu = null }
        )
    }

    // ── Text operations ───────────────────────────────────────────────────

    private fun insert(text: String) {
        jeemRevertPending = false
        currentInputConnection?.commitText(text, 1)
        lastInsertedChar = text.lastOrNull()
        lastInsertTime   = System.currentTimeMillis()
        updatePredictions()
        updateBiDi()
    }

    private fun deleteBack() {
        jeemRevertPending = false
        currentInputConnection?.deleteSurroundingText(1, 0)
        lastInsertedChar = null
        updatePredictions()
        updateBiDi()
    }

    private fun insertSuggestion(suggestion: String) {
        if (jeemRevertPending) {
            jeemRevertPending = false
            currentInputConnection?.deleteSurroundingText(2, 0) // ۚ + space
            insert("ج ")
            return
        }
        val before  = currentInputConnection?.getTextBeforeCursor(100, 0)?.toString() ?: ""
        val partial = before.split(" ", "\n").lastOrNull() ?: ""
        currentInputConnection?.deleteSurroundingText(partial.length, 0)
        insert("$suggestion ")
    }

    private fun isIsolatedJeem(context: String): Boolean {
        if (context.isEmpty() || context.last() != 'ج') return false
        val before = context.dropLast(1)
        if (before.isEmpty() || !before.last().isWhitespace()) return false
        return before.any { !it.isWhitespace() }
    }

    private fun updateBiDi() {
        val text = currentInputConnection?.getTextBeforeCursor(200, 0)?.toString() ?: ""
        predictiveBar?.updateBiDi(text)
    }

    private fun updatePredictions() {
        if (jeemRevertPending) {
            predictiveBar?.update(listOf("ج"))
            return
        }
        if (!KeyboardSettings.getPredictions(this)) {
            predictiveBar?.update(emptyList())
            return
        }
        val before = currentInputConnection?.getTextBeforeCursor(100, 0)?.toString() ?: ""
        val word   = before.split(" ", "\n").lastOrNull() ?: ""
        predictiveBar?.update(
            if (word.isEmpty()) emptyList()
            else listOf(word, "${word}ا", "${word}ه")
        )
    }

    private fun moveCursor(keyCode: Int) {
        val now = SystemClock.uptimeMillis()
        currentInputConnection?.sendKeyEvent(KeyEvent(now, now, KeyEvent.ACTION_DOWN, keyCode, 0))
        currentInputConnection?.sendKeyEvent(KeyEvent(now, now, KeyEvent.ACTION_UP,   keyCode, 0))
    }

    // ── Key handling ──────────────────────────────────────────────────────

    private fun handleKey(key: KeyData) {
        when (key.type) {

            KeyType.CHARACTER -> {
                val now       = System.currentTimeMillis()
                val secondary = key.secondary
                val window    = KeyboardSettings.getDoublePressWindowMs(this)

                if (secondary.isNotEmpty()
                    && KeyboardSettings.getDoublePressEnabled(this)
                    && now - lastKeyPressTime < window) {
                    val before = currentInputConnection
                        ?.getTextBeforeCursor(key.primary.length, 0)?.toString()
                    if (before == key.primary) {
                        repeat(key.primary.length) {
                            currentInputConnection?.deleteSurroundingText(1, 0)
                        }
                        // Honour the doubleAlef setting when ا → اٰ
                        val toInsert = if (key.primary == "ا" && secondary == "اٰ" &&
                            KeyboardSettings.getDoubleAlefStyle(this) == KeyboardSettings.DoubleAlefStyle.ALEF_MADDA) {
                            "آ"
                        } else {
                            secondary
                        }
                        insert(toInsert)
                        lastPressedPrimary = null
                        lastKeyPressTime   = 0L
                        return
                    }
                }

                insert(key.primary)
                lastPressedPrimary = key.primary
                lastKeyPressTime   = now

                if (currentLayer == Layer.LATIN && latinShifted && !latinCapsLock) {
                    latinShifted = false
                    applyLayer()
                }
            }

            KeyType.SPACE -> {
                val now = System.currentTimeMillis()
                // Isolated jeem → auto-replace with small high jeem (U+06DA)
                val spaceCtx = currentInputConnection?.getTextBeforeCursor(50, 0)?.toString() ?: ""
                if (isIsolatedJeem(spaceCtx)) {
                    currentInputConnection?.deleteSurroundingText(1, 0) // remove ج
                    currentInputConnection?.commitText("ۚ ", 1)     // insert ۚ + space
                    lastInsertedChar = ' '
                    lastInsertTime   = now
                    jeemRevertPending = true
                    updatePredictions()
                    updateBiDi()
                    lastPressedPrimary = null
                    return
                }
                // Double-space → period + space: fires only when the previous insert was also a space
                if (lastInsertedChar == ' ' && now - lastInsertTime < doubleSpaceWindowMs) {
                    val before = currentInputConnection?.getTextBeforeCursor(2, 0)?.toString() ?: ""
                    if (before.length >= 2 && before[before.length - 2].isLetter()) {
                        currentInputConnection?.deleteSurroundingText(1, 0)
                        currentInputConnection?.commitText(". ", 1)
                        lastInsertedChar = ' '
                        lastInsertTime   = now
                        return
                    }
                }
                insert(" ")
                lastPressedPrimary = null
            }

            KeyType.BACKSPACE -> {
                deleteBack()
                lastPressedPrimary = null
            }

            KeyType.ENTER -> {
                insert("\n")
                lastPressedPrimary = null
            }

            KeyType.DIACRITIC -> {
                priorToModal  = currentLayer
                currentLayer  = Layer.DIACRITIC
            }

            KeyType.NUMERIC -> {
                priorToModal  = currentLayer
                currentLayer  = Layer.NUMERIC
            }

            // ABC serves two keys: the "ا ب ج" in the numeric/diacritic modals returns
            // to the layer they were entered from (priorToModal); the Latin layer's "ع"
            // always returns to Arabic. Without the LATIN branch, entering numeric *from*
            // Latin leaves priorToModal == LATIN, trapping "ع" in the Latin layer.
            KeyType.ABC -> currentLayer =
                if (currentLayer == Layer.LATIN) Layer.DEFAULT
                else priorToModal.takeIf { it != Layer.NUMERIC && it != Layer.DIACRITIC } ?: Layer.DEFAULT

            KeyType.LATIN -> {
                currentLayer = Layer.LATIN
                if (!KeyboardSettings.getLatinKeyTooltipShown(this)) {
                    KeyboardSettings.setLatinKeyTooltipShown(this)
                    predictiveBar?.showBriefMessage(
                        "Hold  AaBb  to switch keyboard", durationMs = 3500)
                }
            }

            KeyType.SHIFT -> {
                val now = System.currentTimeMillis()
                if (now - lastShiftTime < 350L) {
                    latinCapsLock = !latinCapsLock
                    latinShifted  = latinCapsLock
                } else {
                    if (!latinCapsLock) latinShifted = !latinShifted
                }
                lastShiftTime = now
                applyLayer()
            }

            KeyType.CURSOR_LEFT  -> moveCursor(KeyEvent.KEYCODE_DPAD_RIGHT)
            KeyType.CURSOR_RIGHT -> moveCursor(KeyEvent.KEYCODE_DPAD_LEFT)

            KeyType.GLOBE -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    switchToNextInputMethod(false)
                } else {
                    @Suppress("DEPRECATION")
                    (getSystemService(INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager)
                        ?.switchToNextInputMethod(window?.window?.attributes?.token, false)
                }
            }

            KeyType.EMOJI -> { /* no-op */ }
        }
    }
}
