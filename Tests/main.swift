// Run with ./test.sh. Each case is (clipboard text, expected looksLikeMarkdown).
let cases: [(String, Bool)] = [
    // Markdown
    ("# Title\n\nSome text.", true),
    ("## Section\nbody", true),
    ("Title\n=====\nbody", true),
    ("```\ncode\n```", true),
    ("~~~swift\nlet x = 1\n~~~", true),
    ("| a | b |\n|---|---|\n| 1 | 2 |", true),
    ("|:-|-:|", true),
    ("| a |\n|---|\n| 1 |", true),
    ("See [docs](https://x.com) here", true),
    ("See [readme](docs/readme.md)", true),
    ("Mail [me](mailto:a@b.c)", true),
    ("- [ ] todo\n- [x] done", true),
    ("- one\n- two\nand **bold**", true),
    ("1. first\n2. second\nuse `ls`", true),
    ("# Title\n- a\n- b", true),
    // Not Markdown
    ("hello world, just a note", false),
    ("- one\n- two", false),
    ("Call me at 5. Thanks - Bob", false),
    ("#hashtag not heading", false),
    ("# comment\necho hi\n# another\nls", false),
    ("#!/bin/bash\n# set up\nset -e", false),
    ("f(**kw) and g(**kw2)", false),
    ("def __init__(self): pass\nx = __name__", false),
    ("y = arr[i](./x)", false),
    ("   \n\t\n", false),
]
var failures = 0
for (text, want) in cases {
    let got = Markdown.looksLikeMarkdown(text)
    if got != want { failures += 1 }
    print(got == want ? "ok  " : "FAIL", want ? "md " : "txt", text.debugDescription.prefix(50))
}
print(failures == 0 ? "\nall \(cases.count) passed" : "\n\(failures) of \(cases.count) FAILED")
if failures > 0 { fatalError() }
