# paste-to-file

A Finder Sync extension that adds **Save Clipboard to File** to Finder's
right-click menu, including the menu for empty space in a window (icon, list,
column, and gallery views).

- Writes the clipboard's plain text to `pasted_file.txt` in the folder you
  right-clicked, or `pasted_file.md` if the text looks like Markdown.
- If the name is taken, uses `pasted_file 2.txt`, `pasted_file 3.txt`, and so on.
- Selects the new file in Finder afterwards, so pressing Return renames it.
- Right-clicking a single folder item saves *into* that folder.
- Beeps if the clipboard has no text.

## Build and install

    ./build.sh              # build, ad-hoc sign, install to ~/Applications, enable, restart Finder
    ./build.sh --no-install # build only, into ./build

Requires Xcode (for the SDK and `swiftc`). No Apple developer identity is
needed; the app is ad-hoc signed for local use.

To disable it: System Settings → General → Login Items & Extensions →
File Providers / Finder extensions, or `pluginkit -e ignore -i com.cabird.PasteToFile.FinderSync`.

## Layout

- `Extension/FinderSync.swift`: the menu item and file write
- `Extension/Markdown.swift`: heuristic for picking `.md` vs `.txt`
- `Extension/entitlements.plist`: sandbox plus a read-write exception for `/`
  (extensions must be sandboxed; this lets it write wherever you click)
- `App/main.swift`: a host app with no UI (extensions must be inside an app)
- `build.sh`: builds with `swiftc` directly; there's no Xcode project

## Notes

- Markdown detection: one strong signal (a `#` heading, a code fence, a table,
  a `[link](url)`, or a `- [ ]` task box), or two different weak signals
  (bullets, a numbered list, `**bold**`, `> quote`, `` `code` ``).
- macOS may ask once for permission to let the extension read the clipboard.
