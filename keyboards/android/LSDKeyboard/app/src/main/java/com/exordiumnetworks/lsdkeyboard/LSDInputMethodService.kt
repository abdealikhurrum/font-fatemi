package com.exordiumnetworks.lsdkeyboard

import android.inputmethodservice.InputMethodService
import android.view.KeyEvent
import android.view.View

class LSDInputMethodService : InputMethodService(), LSDKeyboardView.KeyListener {

    private lateinit var keyboardView: LSDKeyboardView

    // -------------------------------------------------------------------------
    // Lifecycle

    override fun onCreateInputView(): View {
        keyboardView = LSDKeyboardView(this).apply {
            listener = this@LSDInputMethodService
        }
        return keyboardView
    }

    override fun onEvaluateInputViewShown(): Boolean {
        super.onEvaluateInputViewShown()
        return true
    }

    // -------------------------------------------------------------------------
    // KeyListener callbacks

    override fun onKeyPressed(key: KeyData) {
        val ic = currentInputConnection ?: return

        when (key.type) {
            KeyType.CHARACTER -> ic.commitText(key.primary, 1)

            KeyType.SPACE -> {
                ic.commitText(" ", 1)
            }

            KeyType.ENTER -> sendDefaultEditorAction(true)

            KeyType.BACKSPACE -> {
                ic.deleteSurroundingText(1, 0)
            }

            KeyType.NUMERIC   -> keyboardView.setLayer(KeyboardLayoutData.numericLayer)
            KeyType.ABC       -> keyboardView.setLayer(KeyboardLayoutData.defaultLayer)
            KeyType.DIACRITIC -> keyboardView.setLayer(KeyboardLayoutData.diacriticLayer)

            KeyType.CURSOR_LEFT, KeyType.CURSOR_RIGHT -> {
                val code = if (key.type == KeyType.CURSOR_LEFT)
                    KeyEvent.KEYCODE_DPAD_LEFT else KeyEvent.KEYCODE_DPAD_RIGHT
                ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, code))
                ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, code))
            }

            KeyType.GLOBE  -> switchToNextInputMethod(false)
            KeyType.EMOJI  -> switchToNextInputMethod(false)
        }
    }

    // Double-press: delete the primary character that was committed on the first
    // tap, then commit the secondary — identical pattern to iOS and macOS.
    override fun onDoubleTap(key: KeyData) {
        val ic = currentInputConnection ?: return
        ic.deleteSurroundingText(1, 0)
        ic.commitText(key.secondary, 1)
        PairCollector.getInstance(this).recordDoublePress(key.primary, key.secondary)
    }

    override fun onBackspaceWord() {
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(100, 0) ?: return
        if (before.isEmpty()) return

        var count = 0
        var hitNonSpace = false
        for (ch in before.reversed()) {
            if (!hitNonSpace) {
                count++
                if (!ch.isWhitespace()) hitNonSpace = true
            } else {
                if (ch.isWhitespace()) break
                count++
            }
        }
        if (count > 0) ic.deleteSurroundingText(count, 0)
    }

    override fun onLongPressAlternate(char: String) {
        currentInputConnection?.commitText(char, 1)
    }
}
