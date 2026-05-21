package com.lisanuddawat.keyboard

import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.SystemClock
import android.view.KeyEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout

class LsdKeyboardService : InputMethodService() {

    private enum class Layer { DEFAULT, NUMERIC, DIACRITIC }

    private var currentLayer = Layer.DEFAULT
        set(value) { field = value; applyLayer() }

    private var keyboardView: KeyboardView? = null
    private var predictiveBar: PredictiveBar? = null
    private var menuView: KeyboardMenuView? = null

    // Double-space tracking (for period insertion)
    private var lastInsertedChar: Char? = null
    private var lastInsertTime: Long = 0
    private val doubleSpaceWindowMs = 400L

    // Double-press tracking (for secondary character)
    private var lastPressedPrimary: String? = null
    private var lastKeyPressTime: Long = 0

    // ── Lifecycle ────────────────────────────────────────────────────────

    override fun onCreateInputView(): View {
        val root = FrameLayout(this)

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
        val layer = when (currentLayer) {
            Layer.DEFAULT -> when (KeyboardSettings.getLayout(this)) {
                KeyboardSettings.LayoutType.LSD            -> KeyboardLayoutData.defaultLayer(this)
                KeyboardSettings.LayoutType.ARABIC_STANDARD -> ArabicStandardLayoutData.defaultLayer(this)
                KeyboardSettings.LayoutType.CRULP_URDU      -> CRULPUrduLayoutData.defaultLayer(this)
            }
            Layer.NUMERIC   -> KeyboardLayoutData.numericLayer
            Layer.DIACRITIC -> KeyboardLayoutData.diacriticLayer
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

    // ── Text operations ───────────────────────────────────────────────────

    private fun insert(text: String) {
        currentInputConnection?.commitText(text, 1)
        lastInsertedChar = text.lastOrNull()
        lastInsertTime   = System.currentTimeMillis()
        updatePredictions()
    }

    private fun deleteBack() {
        currentInputConnection?.deleteSurroundingText(1, 0)
        lastInsertedChar = null
        updatePredictions()
    }

    private fun insertSuggestion(suggestion: String) {
        val before  = currentInputConnection?.getTextBeforeCursor(100, 0)?.toString() ?: ""
        val partial = before.split(" ", "\n").lastOrNull() ?: ""
        currentInputConnection?.deleteSurroundingText(partial.length, 0)
        insert("$suggestion ")
    }

    private fun updatePredictions() {
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
            }

            KeyType.SPACE -> {
                val now = System.currentTimeMillis()
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

            KeyType.DIACRITIC -> currentLayer = Layer.DIACRITIC

            KeyType.NUMERIC -> currentLayer = Layer.NUMERIC

            KeyType.ABC -> currentLayer = Layer.DEFAULT

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
