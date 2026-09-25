import Foundation

/// Heuristic Markdown sniffer. One strong signal (heading, code fence, table,
/// link, task box) is enough; otherwise it takes two different weak signals.
enum Markdown {
    private static let strong = [
        #"(?m)^#{1,6} \S"#,                         // # Heading
        #"(?m)^\s*(```|~~~)"#,                      // code fence
        #"(?m)^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$"#, // table separator
        #"\[[^\]\n]+\]\((https?://|/|\.|#)[^)\s]*\)"#,  // [text](url)
        #"(?m)^\s*[-*+] \[[ xX]\] "#,               // - [ ] task
    ]
    private static let weak = [
        #"(?m)^\s*[-*+] \S"#,                       // bullet
        #"(?m)^\s*\d+\. \S"#,                       // numbered list
        #"(\*\*|__)[^\s*_][^\n]*?(\*\*|__)"#,       // **bold**
        #"(?m)^> "#,                                // blockquote
        #"`[^`\n]+`"#,                              // `inline code`
    ]

    static func looksLikeMarkdown(_ text: String) -> Bool {
        if strong.contains(where: { matches($0, text) }) { return true }
        return weak.filter { matches($0, text) }.count >= 2
    }

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}
