package com.lisanuddawat.keyboard

import android.view.inputmethod.InputConnection

object BiDiAnalyzer {

    enum class IssueType { TRAILING_LTR, EMBEDDED_LTR, WRONG_START }

    data class Issue(
        val type: IssueType,
        val previewRtl: String,
        val previewLtr: String
    )

    fun analyze(text: String): Issue? {
        if (text.isBlank()) return null
        val hasRTL = text.any { isRTL(it) }
        val hasLTR = text.any { isLTR(it) }
        if (!hasRTL || !hasLTR) return null

        // Wrong start: first strong character is LTR so bubble renders LTR
        val firstStrong = text.firstOrNull { isRTL(it) || isLTR(it) }
        if (firstStrong != null && isLTR(firstStrong)) {
            val ltrRun = buildString { for (c in text) { if (isLTR(c) || c.isDigit()) append(c) else break } }.take(4)
            val rtlSample = text.firstOrNull { isRTL(it) }?.toString() ?: "ع"
            return Issue(IssueType.WRONG_START, rtlSample, ltrRun)
        }

        // Trailing LTR: text ends with Latin/digits
        val trimmed = text.trimEnd()
        if (trimmed.isNotEmpty() && (isLTR(trimmed.last()) || trimmed.last().isDigit())) {
            val ltrRun = buildString {
                for (c in trimmed.reversed()) {
                    if (isLTR(c) || c.isDigit() || c == '.' || c == '-') append(c) else break
                }
            }.reversed().take(4)
            val rtlSample = trimmed.lastOrNull { isRTL(it) }?.toString() ?: "ع"
            return Issue(IssueType.TRAILING_LTR, rtlSample, ltrRun)
        }

        // Embedded LTR: Latin/digit run surrounded by RTL on both sides
        var i = 0
        var seenRTL = false
        while (i < text.length) {
            val c = text[i]
            when {
                isRTL(c) -> { seenRTL = true; i++ }
                seenRTL && (isLTR(c) || c.isDigit()) -> {
                    val run = buildString {
                        var j = i
                        while (j < text.length && (isLTR(text[j]) || text[j].isDigit() || text[j] == '.')) {
                            append(text[j++])
                        }
                    }
                    if (i + run.length < text.length && text.substring(i + run.length).any { isRTL(it) }) {
                        val rtlSample = text.lastOrNull { isRTL(it) }?.toString() ?: "ع"
                        return Issue(IssueType.EMBEDDED_LTR, rtlSample, run.take(4))
                    }
                    i += run.length.coerceAtLeast(1)
                }
                else -> i++
            }
        }

        return null
    }

    // ── Fixes ─────────────────────────────────────────────────────────────

    fun applySmartFix(issue: Issue, ic: InputConnection) {
        when (issue.type) {
            IssueType.TRAILING_LTR, IssueType.EMBEDDED_LTR -> insertRlmAtCursor(ic)
            IssueType.WRONG_START                          -> insertRlmAtStart(ic)
        }
    }

    fun insertRlmAtStart(ic: InputConnection) {
        val before = ic.getTextBeforeCursor(10000, 0)?.toString() ?: return
        val after  = ic.getTextAfterCursor(10000, 0)?.toString()  ?: ""
        ic.deleteSurroundingText(before.length, after.length)
        ic.commitText("‏$before$after", 1)
    }

    fun insertRlmAtCursor(ic: InputConnection) {
        ic.commitText("‏", 1)
    }

    fun wrapSelectionAsLtr(ic: InputConnection) {
        val sel = ic.getSelectedText(0)?.toString()
        if (!sel.isNullOrEmpty()) ic.commitText("⁦$sel⁩", 1)
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private fun isRTL(c: Char): Boolean {
        val d = Character.getDirectionality(c)
        return d == Character.DIRECTIONALITY_RIGHT_TO_LEFT ||
               d == Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC
    }

    private fun isLTR(c: Char): Boolean =
        Character.getDirectionality(c) == Character.DIRECTIONALITY_LEFT_TO_RIGHT
}
