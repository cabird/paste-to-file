import Foundation

/// Heuristic Markdown sniffer. One strong signal is enough; otherwise it takes
/// two different weak signals. Tuned to keep code (shell/Python comments,
/// `**kwargs`, `arr[i](x)`) from being mistaken for Markdown.
enum Markdown {
    private static let strong = [
        #"(?m)^#{2,6}[ \t]+\S"#,                            // ## Heading (level 2+)
        #"(?m)^#[ \t]+\S[^\n]*\n[ \t]*\n"#,                 // # Heading followed by a blank line
        #"(?m)^\S[^\n]*\n={3,}[ \t]*$"#,                    // Setext heading underlined with ===
        #"(?m)^[ \t]*(```|~~~)"#,                           // code fence
        #"(?m)^[ \t]*\|?[ \t]*:?-+:?[ \t]*(\|[ \t]*:?-+:?[ \t]*)+\|?[ \t]*$"#, // |---|---|
        #"(?m)^[ \t]*\|[ \t]*:?-{3,}:?[ \t]*\|[ \t]*$"#,    // |---| (one column)
        #"(?<![\w\]])\[[^\]\n]+\]\([^)\s]+\)"#,             // [text](url), not arr[i](x)
        #"(?m)^[ \t]*[-*+][ \t]+\[[ xX]\][ \t]"#,           // - [ ] task
    ]
    private static let weak = [
        #"(?m)^#[ \t]+\S"#,                                 // # Heading (or a code comment)
        #"(?m)^[ \t]*[-*+][ \t]+\S"#,                       // bullet
        #"(?m)^[ \t]*\d+\.[ \t]+\S"#,                       // numbered list
        #"(?<![\w*(])\*\*[^\s*][^*\n]*?(?<=\S)\*\*(?![\w*])"#, // **bold**, not f(**kw)
        #"(?m)^>[ \t]"#,                                    // blockquote
        #"`[^`\n]+`"#,                                      // `inline code`
    ]

    static func looksLikeMarkdown(_ text: String) -> Bool {
        if strong.contains(where: { matches($0, text) }) { return true }
        return weak.filter { matches($0, text) }.count >= 2
    }

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}
