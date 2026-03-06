import Foundation
#if canImport(AppKit)
import AppKit
#endif

enum TextExportResult: Equatable {
    case success(path: String)
    case cancelled
    case permissionDenied
    case writeFailed
    case unsupported
}

protocol FileServiceType {
    func directoryExists(_ path: String) -> Bool
    @discardableResult
    func copyTextToClipboard(_ text: String) -> Bool
    func saveTextWithPanel(defaultFileName: String, content: String) -> TextExportResult
    func revealInFinder(_ path: String)
    func pickDirectory() -> String?
}

final class FileService: FileServiceType {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func directoryExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func readFile(_ path: String) throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }

    func writeFile(_ path: String, content: String) throws {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    @discardableResult
    func copyTextToClipboard(_ text: String) -> Bool {
#if canImport(AppKit)
        let board = NSPasteboard.general
        board.clearContents()
        return board.setString(text, forType: .string)
#else
        return false
#endif
    }

    func saveTextWithPanel(defaultFileName: String, content: String) -> TextExportResult {
#if canImport(AppKit)
        let panel = NSSavePanel()
        panel.title = "导出同步日志"
        panel.nameFieldStringValue = defaultFileName
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let targetURL = panel.url else {
            return .cancelled
        }
        do {
            try content.write(to: targetURL, atomically: true, encoding: .utf8)
            return .success(path: targetURL.path)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain {
                if nsError.code == NSFileWriteNoPermissionError || nsError.code == NSFileReadNoPermissionError {
                    return .permissionDenied
                }
            }
            return .writeFailed
        }
#else
        return .unsupported
#endif
    }

    func revealInFinder(_ path: String) {
#if canImport(AppKit)
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
#endif
    }

    func pickDirectory() -> String? {
#if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.title = "选择目录"
        panel.prompt = "选择"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        return panel.runModal() == .OK ? panel.url?.path : nil
#else
        return nil
#endif
    }
}
