package com.lisanuddawat.keyboard

import android.inputmethodservice.InputMethodService
import android.os.Build
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout

class LsdKeyboardService : InputMethodService() {

    private enum class Layer { DEFAULT, SHIFT, NUMERIC }

    private var currentLayer = Layer.DEFAULT
        set(value) { field = value; applyLayer() }

    private var shiftActive = false
        set(value) { field = value; keyboardView?.updateShiftAppearance(value, shiftLocked) }

    private var shiftLocked = false

    private var keyboardView: KeyboardView? = null
    private var predictiveBar: PredictiveBar? = null

    private var lastInsertedChar: Char? = null
    private var lastInsertTime: Long = 0
    private val doubleSpaceWindowMs = 400L

    // ------------------------------------------------------------------  lifecycle

    override fun onCreateInputView(): View {
        // Root FrameLayout — keyboard content sits inside; callout/popup overlays float on top
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
                override fun longPressAlternateSelected(character: String) { handleLongPress(character) }
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
            Layer.DEFAULT -> keyboardView?.configure(KeyboardLayoutData.defaultLayer)
            Layer.SHIFT   -> keyboardView?.configure(KeyboardLayoutData.shiftLayer)
            Layer.NUMERIC -> keyboardView?.configure(KeyboardLayoutData.numericLayer)
        }
        keyboardView?.updateShiftAppearance(shiftActive, shiftLocked)
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

    // ------------------------------------------------------------------  key handling (mirrors iOS KeyboardViewController)

    private fun handleKey(key: KeyData) {
        when (key.type) {

            KeyType.CHARACTER -> {
                insert(key.primary)
                if (shiftActive && !shiftLocked) {
                    shiftActive  = false
                    currentLayer = Layer.DEFAULT
                }
            }

            KeyType.SPACE -> {
                val now = System.currentTimeMillis()
                val lc  = lastInsertedChar
                // Double-space → period + space, matching iOS native behaviour
                if (lc != null && lc != ' ' && lc != '\n'
                    && now - lastInsertTime < doubleSpaceWindowMs) {
                    val before = currentInputConnection?.getTextBeforeCursor(1, 0)?.toString() ?: ""
                    if (before.lastOrNull()?.isLetter() == true) {
                        currentInputConnection?.deleteSurroundingText(0, 0)
                        currentInputConnection?.commitText(". ", 1)
                        lastInsertedChar = ' '
                        lastInsertTime   = now
                        return
                    }
                }
                insert(" ")
            }

            KeyType.BACKSPACE -> deleteBack()

            KeyType.ENTER -> insert("\n")

            KeyType.SHIFT -> when {
                currentLayer == Layer.DEFAULT && !shiftActive -> {
                    currentLayer = Layer.SHIFT
                    shiftActive  = true
                    shiftLocked  = false
                }
                currentLayer == Layer.SHIFT && shiftActive && !shiftLocked -> {
                    // Second tap: caps lock
                    shiftLocked = true
                    keyboardView?.updateShiftAppearance(true, true)
                }
                currentLayer == Layer.SHIFT && shiftActive && shiftLocked -> {
                    // Third tap: off
                    currentLayer = Layer.DEFAULT
                    shiftActive  = false
                    shiftLocked  = false
                }
                else -> Unit
            }

            KeyType.NUMERIC -> {
                currentLayer = Layer.NUMERIC
                shiftActive  = false
                shiftLocked  = false
            }

            KeyType.ABC -> {
                currentLayer = Layer.DEFAULT
                shiftActive  = false
                shiftLocked  = false
            }

            KeyType.GLOBE -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    switchToNextInputMethod(false)
                } else {
                    @Suppress("DEPRECATION")
                    (getSystemService(INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager)
                        ?.switchToNextInputMethod(window?.window?.attributes?.token, false)
                }
            }
        }
    }

    private fun handleLongPress(character: String) {
        insert(character)
        if (shiftActive && !shiftLocked) {
            shiftActive  = false
            currentLayer = Layer.DEFAULT
        }
    }
}
