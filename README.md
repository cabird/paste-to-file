# paste-to-file

Right-click in any Finder window and choose **Save Clipboard to File**. The
text on your clipboard becomes a new file in that folder, already selected so
you can press Return and rename it.

```
┌──────────────────────────────┐
│ New Folder                   │
│ Get Info                     │
│ ──────────────────────────── │
│ 📋 Save Clipboard to File     │   →  pasted_file.txt   (or pasted_file.md)
│ ──────────────────────────── │
│ Sort By                    ▸ │
│ Show View Options            │
└──────────────────────────────┘
```

macOS has no built-in way to paste text straight into a folder as a file.
Automator Quick Actions only appear when you right-click a file or folder, not
empty space in a window. This project is a small **Finder Sync extension**, the
one supported way to add an item to that background menu.

## Features

- Works in icon, list, column and gallery view, when you right-click empty
  space or right-click an item.
- **Picks `.md` or `.txt` for you:** if the clipboard text looks like Markdown,
  the file is `pasted_file.md`; otherwise it's `pasted_file.txt`.
- **Never overwrites:** it uses `pasted_file 2.txt`, `pasted_file 3.txt` and so
  on when the name is taken.
- **Selects the new file** so a single press of Return starts renaming it.
- Right-clicking a single folder saves *into* that folder. Right-clicking a file
  saves next to it.
- Line endings are normalized to LF, and a trailing newline is added.
- Text only. It beeps and does nothing if the clipboard holds no text (for
  example an image) or only whitespace, or if it holds files copied in Finder.
  Otherwise you would get a file containing just the copied file's name.

## Requirements

- macOS 13 or later (developed and tested on macOS 26). Builds a universal
  binary for Apple silicon and Intel.
- Xcode, for the macOS SDK and `swiftc`. The Command Line Tools alone are not
  enough.
- No Apple Developer account. The app is ad-hoc signed for use on your own Mac.

## Install

```sh
git clone https://github.com/cabird/paste-to-file.git
cd paste-to-file
./build.sh
```

`build.sh` compiles the app and extension, signs them, copies
`PasteToFile.app` to `~/Applications`, registers and enables the extension,
and restarts Finder. When it finishes, the line it prints should start with
`+`, which means the extension is enabled:

```
+    com.cabird.PasteToFile.FinderSync(1.0)  ...  ~/Applications/PasteToFile.app/...
```

To build without installing, run `./build.sh --no-install`. The output goes to
`./build`. To run the Markdown-detection unit tests, run `./test.sh`.

The first time you use it, macOS may ask whether the extension can read the
clipboard. Choose **Allow**.

## Uninstall

```sh
pluginkit -e ignore -i com.cabird.PasteToFile.FinderSync
rm -rf ~/Applications/PasteToFile.app
killall Finder
```

## How Markdown is detected

The check is deliberately cautious. Plain prose, and even a simple dash list,
stay `.txt`. The text counts as Markdown if it has **one strong signal**:

| Strong signal | Example |
|---|---|
| Heading, level 2 or deeper | `## Section` |
| Level-1 heading followed by a blank line | `# Title` then an empty line |
| Setext heading | `Title` underlined with `===` |
| Code fence | ` ``` ` or `~~~` |
| Table separator row | `\|---\|---\|` |
| Inline link | `[docs](https://…)`, `[readme](docs/readme.md)` |
| Task list item | `- [ ] todo` |

or **two different weak signals**: a `# heading`, a bulleted list, a numbered
list, `**bold**`, a `> quote` or `` `inline code` ``.

Shell and Python code shouldn't come out as `.md`. A lone `# comment` is only a
weak signal, `**kwargs` isn't bold, and `arr[i](x)` isn't a link. The test
cases in [`Tests/main.swift`](Tests/main.swift) cover these.

The rules are in [`Extension/Markdown.swift`](Extension/Markdown.swift) if you
want to tune them.

## How it works

```
PasteToFile.app                      host app with no UI; macOS requires extensions to live in an app
└── Contents/PlugIns/
    └── PasteToFileFinderSync.appex  the Finder Sync extension (runs inside Finder's menu system)
```

- [`Extension/FinderSync.swift`](Extension/FinderSync.swift): a `FIFinderSync`
  subclass that watches `/`, so the menu appears in every folder. It adds the
  menu item, works out which folder you clicked
  (`targetedURL` / `selectedItemURLs`), writes the file and selects it.
- [`Extension/entitlements.plist`](Extension/entitlements.plist): app
  extensions must be sandboxed. A read-write exception for `/` lets the
  extension write into whatever folder you right-click.
- The file is written without overwriting and without a temporary file. If
  the name is already taken, it moves on to the next name. This avoids races
  and privacy prompts triggered by temporary files.
- [`build.sh`](build.sh): builds with `swiftc` directly; there's no Xcode
  project. The extension binary is linked with `-e _NSExtensionMain`, the
  entry point Xcode normally supplies.
- [`test.sh`](test.sh): compiles and runs the Markdown heuristic tests.

## Troubleshooting

**The menu item doesn't appear.** Check that the extension is enabled:

```sh
pluginkit -m -A -v -i com.cabird.PasteToFile.FinderSync
```

A leading `+` means enabled, `-` means disabled, and no output means it isn't
registered. Run `./build.sh` again, or turn it on in **System Settings →
General → Login Items & Extensions → Extensions → Added Extensions**. Then
restart Finder with `killall Finder`.

**Registration fails right after a rebuild.** The macOS plugin daemon (`pkd`)
registers extensions asynchronously and is slow right after the previous copy
is removed. `build.sh` retries until the extension shows as enabled, so running
it once more usually fixes this.

**Another Finder Sync extension (Dropbox, OneDrive, Google Drive) is active.**
They coexist. Finder shows every extension's menu items.

**It beeps in Desktop, Documents, Downloads or iCloud Drive.** Those folders
are privacy-protected, and the sandbox exception doesn't override that. If
macOS asks whether PasteToFile may access the folder, allow it. You can also
grant access in **System Settings → Privacy & Security → Files and Folders**.
The app is ad-hoc signed, so its signature changes with every rebuild. macOS
may then forget those permissions and ask again.

**Nothing happens when you click it.** Check the extension's log messages:

```sh
log show --last 5m --predicate 'process == "PasteToFileFinderSync"'
```

## Customizing

- **Base filename:** `"pasted_file"` in `saveClipboard(_:)`
- **Menu text and icon:** `menu(for:)` in `FinderSync.swift`
- **Bundle IDs:** `com.cabird.PasteToFile` in both `Info.plist` files and
  `EXT_ID` in `build.sh`. Change all three together if you fork this.

## License

MIT. See [LICENSE](LICENSE).
