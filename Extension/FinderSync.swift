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
        menu.addItem(item)
        return menu
    }

    @objc func saveClipboard(_ sender: AnyObject?) {
        guard let folder = targetFolder() else { NSSound.beep(); return }
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            NSSound.beep(); return
        }

        let ext = Markdown.looksLikeMarkdown(text) ? "md" : "txt"
        let url = uniqueURL(in: folder, base: "pasted_file", ext: ext)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            NSLog("PasteToFile: failed to write \(url.path): \(error)")
            NSSound.beep()
        }
    }

    /// Background click: the folder being viewed. Item click: the clicked
    /// folder if exactly one folder is selected, otherwise its parent.
    private func targetFolder() -> URL? {
        let controller = FIFinderSyncController.default()
        if let selected = controller.selectedItemURLs(), selected.count == 1,
           (try? selected[0].resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true,
           selected[0] != controller.targetedURL() {
            return selected[0]
        }
        return controller.targetedURL()
    }

    private func uniqueURL(in folder: URL, base: String, ext: String) -> URL {
        let fm = FileManager.default
        var url = folder.appendingPathComponent("\(base).\(ext)")
        var n = 2
        while fm.fileExists(atPath: url.path) {
            url = folder.appendingPathComponent("\(base) \(n).\(ext)")
            n += 1
        }
        return url
    }
}
