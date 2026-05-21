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

    // Double-space tracking (for period insertion)
    private var lastInsertedChar: Char? = null
    private var lastInsertTime: Long = 0
    private val doubleSpaceWindowMs = 400L

    // Double-press tracking (for secondary character)
    private var lastPressedPrimary: String? = null
    private var lastKeyPressTime: Long = 0
    private val doublePressWindowMs = 400L

    // ------------------------------------------------------------------  lifecycle

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
                override fun predictiveBarDidSelect(suggestion: String) {
                    insertSuggestion(suggestion)
                }
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

    // ------------------------------------------------------------------  layer

    private fun applyLayer() {
        when (currentLayer) {
            Layer.DEFAULT   -> keyboardView?.configure(KeyboardLayoutData.defaultLayer)
            Layer.NUMERIC   -> keyboardView?.configure(KeyboardLayoutData.numericLayer)
            Layer.DIACRITIC -> keyboardView?.configure(KeyboardLayoutData.diacriticLayer)
        }
    }

    // ------------------------------------------------------------------  text operations

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
        val before = currentInputConnection?.getTextBeforeCursor(100, 0)?.toString() ?: ""
        val word   = before.split(" ", "\n").lastOrNull() ?: ""
        predictiveBar?.update(
            if (word.isEmpty()) emptyList()
            else listOf(word, "${word}ا", "${word}ه")   // placeholder — replace with model
        )
    }

    private fun moveCursor(keyCode: Int) {
        val now = SystemClock.uptimeMillis()
        currentInputConnection?.sendKeyEvent(KeyEvent(now, now, KeyEvent.ACTION_DOWN, keyCode, 0))
        currentInputConnection?.sendKeyEvent(KeyEvent(now, now, KeyEvent.ACTION_UP,   keyCode, 0))
    }

    // ------------------------------------------------------------------  key handling

    private fun handleKey(key: KeyData) {
        when (key.type) {

            KeyType.CHARACTER -> {
                val now = System.currentTimeMillis()
                val secondary = key.secondary

                // Double-press: if the same primary was just inserted, replace it with secondary.
                if (secondary.isNotEmpty() && now - lastKeyPressTime < doublePressWindowMs) {
                    val before = currentInputConnection
                        ?.getTextBeforeCursor(key.primary.length, 0)?.toString()
                    if (before == key.primary) {
                        repeat(key.primary.length) {
                            currentInputConnection?.deleteSurroundingText(1, 0)
                        }
                        insert(secondary)
                        // Reset so a third press starts fresh
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
                // Double-space → period + space: fires only when the previous insert was
                // also a space (i.e. user pressed space twice quickly), not on every word.
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

            // In RTL text: visual ← moves cursor toward the end of the string (DPAD_RIGHT)
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

            KeyType.EMOJI -> { /* no-op — no layer defined yet */ }
        }
    }
}
