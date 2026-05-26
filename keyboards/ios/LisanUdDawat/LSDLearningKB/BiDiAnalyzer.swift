import Foundation

// Detects and fixes bidirectional text issues in mixed Arabic/Latin strings.
// Ported from the Android BiDiAnalyzer.kt; text operations are expressed via
// BiDiTextProxy so the analyzer stays UIKit-independent.

protocol BiDiTextProxy {
    var textBeforeCursor: String { get }
    var selectedText: String? { get }
    func deleteBeforeCursor(_ count: Int)
    func insertAtCursor(_ text: String)
}

enum BiDiAnalyzer {

    enum IssueType { case trailingLTR, embeddedLTR, wrongStart }

    struct Issue {
        let type: IssueType
        let previewRtl: String
        let previewLtr: String
    }

    static func analyze(_ text: String) -> Issue? {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let hasRTL = text.contains(where: isRTL)
        let hasLTR = text.contains(where: isLTR)
        guard hasRTL && hasLTR else { return nil }

        // Wrong start: first strong character is LTR → whole bubble renders LTR
        if let first = text.first(where: { isRTL($0) || isLTR($0) }), isLTR(first) {
            let ltrRun = String(text.prefix(while: { isLTR($0) || $0.isNumber }).prefix(4))
            let rtlSample = text.first(where: isRTL).map(String.init) ?? "ع"
            return Issue(type: .wrongStart, previewRtl: rtlSample, previewLtr: ltrRun)
        }

        // Trailing LTR: text ends with Latin/digits
        let trimmed = text.trimmingCharacters(in: .init(charactersIn: " \t"))
        if let last = trimmed.last, (isLTR(last) || last.isNumber) {
            let ltrRun = String(trimmed.reversed().prefix(while: {
                isLTR($0) || $0.isNumber || $0 == "." || $0 == "-"
            }).reversed().prefix(4))
            let rtlSample = trimmed.last(where: isRTL).map(String.init) ?? "ع"
            return Issue(type: .trailingLTR, previewRtl: rtlSample, previewLtr: ltrRun)
        }

        // Embedded LTR: Latin/digit run surrounded by RTL on both sides
        var seenRTL = false
        var idx = text.startIndex
        while idx < text.endIndex {
            let ch = text[idx]
            if isRTL(ch) {
                seenRTL = true
            } else if seenRTL && (isLTR(ch) || ch.isNumber) {
                let runStart = idx
                var runEnd   = idx
                while runEnd < text.endIndex && (isLTR(text[runEnd]) || text[runEnd].isNumber || text[runEnd] == ".") {
                    runEnd = text.index(after: runEnd)
                }
                let afterRun = text[runEnd...]
                if afterRun.contains(where: isRTL) {
                    let run = String(text[runStart..<runEnd].prefix(4))
                    let rtlSample = text.last(where: isRTL).map(String.init) ?? "ع"
                    return Issue(type: .embeddedLTR, previewRtl: rtlSample, previewLtr: run)
                }
                idx = runEnd
                continue
            }
            idx = text.index(after: idx)
        }

        return nil
    }

    // MARK: - Fixes

    static func applySmartFix(issue: Issue, proxy: BiDiTextProxy) {
        switch issue.type {
        case .trailingLTR: fixAtTrailingBoundary(proxy: proxy)
        case .embeddedLTR: insertRlmAtCursor(proxy: proxy)
        case .wrongStart:  insertRlmAtLineStart(proxy: proxy)
        }
    }

    // Inserts RLM at the RTL→LTR boundary rather than at the cursor end.
    static func fixAtTrailingBoundary(proxy: BiDiTextProxy) {
        let before = String((proxy.textBeforeCursor).suffix(200))
        var i = before.endIndex
        while i > before.startIndex {
            let prev = before.index(before: i)
            let ch   = before[prev]
            if isLTR(ch) || ch.isNumber || ch == "." || ch == "-" { i = prev } else { break }
        }
        let ltrRun = String(before[i...])
        if ltrRun.isEmpty { insertRlmAtCursor(proxy: proxy); return }
        proxy.deleteBeforeCursor(ltrRun.count)
        proxy.insertAtCursor("\u{200F}" + ltrRun)   // RLM + run
    }

    static func insertRlmAtLineStart(proxy: BiDiTextProxy) {
        let before = String(proxy.textBeforeCursor.suffix(500))
        let lineStart = before.lastIndex(of: "\n").map { before.index(after: $0) } ?? before.startIndex
        let lineContent = String(before[lineStart...])
        if lineContent.isEmpty { proxy.insertAtCursor("\u{200F}"); return }
        proxy.deleteBeforeCursor(lineContent.count)
        proxy.insertAtCursor("\u{200F}" + lineContent)
    }

    static func insertRlmAtCursor(proxy: BiDiTextProxy) {
        proxy.insertAtCursor("\u{200F}")    // U+200F RIGHT-TO-LEFT MARK
    }

    static func wrapSelectionAsLtr(proxy: BiDiTextProxy) {
        guard let sel = proxy.selectedText, !sel.isEmpty else { return }
        // U+2066 LEFT-TO-RIGHT ISOLATE … U+2069 POP DIRECTIONAL ISOLATE
        proxy.insertAtCursor("\u{2066}" + sel + "\u{2069}")
    }

    // MARK: - Character direction helpers

    static func isRTL(_ ch: Character) -> Bool {
        for scalar in ch.unicodeScalars {
            let v = scalar.value
            if (v >= 0x0600 && v <= 0x06FF) ||   // Arabic
               (v >= 0x0750 && v <= 0x077F) ||   // Arabic Supplement
               (v >= 0x08A0 && v <= 0x08FF) ||   // Arabic Extended-A/B
               (v >= 0xFB50 && v <= 0xFDFF) ||   // Arabic Presentation Forms-A
               (v >= 0xFE70 && v <= 0xFEFF) ||   // Arabic Presentation Forms-B
               (v >= 0x0590 && v <= 0x05FF) ||   // Hebrew
               (v >= 0xFB00 && v <= 0xFB4F) {    // Alphabetic Presentation Forms (Hebrew)
                return true
            }
        }
        return false
    }

    static func isLTR(_ ch: Character) -> Bool {
        for scalar in ch.unicodeScalars {
            let v = scalar.value
            if (v >= 0x0041 && v <= 0x005A) ||   // A–Z
               (v >= 0x0061 && v <= 0x007A) ||   // a–z
               (v >= 0x00C0 && v <= 0x00D6) ||   // Latin-1 Supplement upper
               (v >= 0x00D8 && v <= 0x00F6) ||
               (v >= 0x00F8 && v <= 0x00FF) {    // Latin-1 Supplement lower
                return true
            }
        }
        return false
    }
}

// Convenience extension so Collection elements can be scanned with the static helpers.
private extension StringProtocol {
    func last(where predicate: (Character) -> Bool) -> Character? {
        reversed().first(where: predicate)
    }
}
