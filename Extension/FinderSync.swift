import Cocoa
import FinderSync

/// Finder Sync extension that adds "Save Clipboard to File" to Finder's
/// right-click menus, including the empty-background menu of a window.
@objc(FinderSync)
class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // Watch the whole filesystem so the menu appears in every folder.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        guard menuKind == .contextualMenuForContainer || menuKind == .contextualMenuForItems else {
            return menu
        }
        let item = NSMenuItem(title: "Save Clipboard to File",
                              action: #selector(saveClipboard(_:)),
                              keyEquivalent: "")
        item.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
        // Finder copies menu items, but the tag survives; it tells the action
        // which menu was clicked.
        item.tag = Int(menuKind.rawValue)
        menu.addItem(item)
        return menu
    }

    @objc func saveClipboard(_ sender: AnyObject?) {
        let kind = (sender as? NSMenuItem).flatMap { FIMenuKind(rawValue: UInt($0.tag)) }
        guard let folder = targetFolder(for: kind),
              let text = clipboardText() else {
            NSSound.beep(); return
        }

        let ext = Markdown.looksLikeMarkdown(text) ? "md" : "txt"
        guard let url = writeUnique(Data(text.utf8), in: folder, base: "pasted_file", ext: ext) else {
            NSSound.beep(); return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    /// The clipboard's text, normalized to LF line endings with a trailing
    /// newline. Returns nil for no text, whitespace-only text, or copied
    /// Finder files (whose "text" is just the file name).
    private func clipboardText() -> String? {
        let pb = NSPasteboard.general
        if pb.types?.contains(.fileURL) == true { return nil }
        guard var text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        text = text.replacingOccurrences(of: "\r\n", with: "\n")
        if !text.hasSuffix("\n") { text += "\n" }
        return text
    }

    /// Background click: the folder being viewed. Item click: the clicked
    /// folder, or the folder containing the clicked file.
    private func targetFolder(for kind: FIMenuKind?) -> URL? {
        let controller = FIFinderSyncController.default()
        if kind == .contextualMenuForItems,
           let selected = controller.selectedItemURLs(), selected.count == 1 {
            let url = selected[0]
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            let isFolder = values?.isDirectory == true && values?.isPackage != true
            return isFolder ? url : url.deletingLastPathComponent()
        }
        return controller.targetedURL()
    }

    /// Writes `data` to the first free "base.ext", "base 2.ext", ... name.
    /// Uses no-overwrite (not atomic) writes so a file created between the
    /// check and the write is never clobbered, and no temp file is involved.
    private func writeUnique(_ data: Data, in folder: URL, base: String, ext: String) -> URL? {
        for n in 1...1000 {
            let name = n == 1 ? "\(base).\(ext)" : "\(base) \(n).\(ext)"
            let url = folder.appendingPathComponent(name)
            do {
                try data.write(to: url, options: .withoutOverwriting)
                return url
            } catch let error as CocoaError where error.code == .fileWriteFileExists {
                continue
            } catch {
                NSLog("PasteToFile: failed to write \(url.path): \(error)")
                return nil
            }
        }
        return nil
    }
}
