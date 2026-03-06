import Foundation

protocol GitServiceType {
    func clone(repoURL: String, branch: String?, to localPath: String) -> Result<Void, Error>
    func pull(localPath: String, branch: String?) -> Result<Void, Error>
}

extension GitServiceType {
    func cloneAsync(repoURL: String, branch: String?, to localPath: String) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: clone(repoURL: repoURL, branch: branch, to: localPath))
            }
        }
    }

    func pullAsync(localPath: String, branch: String?) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: pull(localPath: localPath, branch: branch))
            }
        }
    }
}

struct GitServiceError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class GitService: GitServiceType {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func clone(repoURL: String, branch: String?, to localPath: String) -> Result<Void, Error> {
        let parentPath = (localPath as NSString).deletingLastPathComponent
        do {
            try fileManager.createDirectory(
                atPath: parentPath,
                withIntermediateDirectories: true
            )
        } catch {
            return .failure(error)
        }
        if fileManager.fileExists(atPath: localPath) {
            return .failure(GitServiceError(message: "目标目录已存在"))
        }
        var arguments = ["clone"]
        if let branch, !branch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            arguments.append(contentsOf: ["--branch", branch, "--single-branch"])
        }
        arguments.append(contentsOf: [repoURL, localPath])
        return runGit(arguments: arguments, workingDirectory: parentPath)
    }

    func pull(localPath: String, branch: String?) -> Result<Void, Error> {
        guard fileManager.fileExists(atPath: localPath) else {
            return .failure(GitServiceError(message: "本地目录不存在"))
        }
        guard fileManager.fileExists(atPath: "\(localPath)/.git") else {
            return .failure(GitServiceError(message: "目标目录不是 Git 仓库"))
        }
        let branchName = (branch?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? branch!.trimmingCharacters(in: .whitespacesAndNewlines)
            : "HEAD"
        return runGit(arguments: ["pull", "origin", branchName], workingDirectory: localPath)
    }

    private func runGit(arguments: [String], workingDirectory: String) -> Result<Void, Error> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory, isDirectory: true)

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                return .success(())
            }
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Git 命令执行失败"
            return .failure(GitServiceError(message: output))
        } catch {
            return .failure(error)
        }
    }
}
