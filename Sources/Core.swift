import Foundation

struct CleanItem: Identifiable, Hashable {
    var id: String { url.path }
    let url: URL
    let category: String
    let reason: String
    let recommended: Bool
    let bytes: Int64
}

struct ScanResult {
    let app: URL
    let name: String
    let bundleID: String
    let items: [CleanItem]
    let notes: [String]
}

enum CleanerError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let s) = self { return s }; return nil }
}

enum Scanner {
    static let locations = ["Application Support", "Caches", "Preferences", "HTTPStorages", "WebKit", "Saved Application State", "Logs", "Containers", "Application Scripts"]
    static func plist(_ url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
    }
    static func identity(_ app: URL) -> String? {
        plist(app.appendingPathComponent("Contents/Info.plist"))?["CFBundleIdentifier"] as? String
    }
    static func isWithin(_ child: URL, _ parent: URL) -> Bool {
        let a = child.standardizedFileURL.path, b = parent.standardizedFileURL.path
        return a == b || a.hasPrefix(b + "/")
    }
    static func size(_ url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.isSymbolicLinkKey, .isRegularFileKey, .fileAllocatedSizeKey]
        if let v = try? url.resourceValues(forKeys: keys), v.isSymbolicLink == true { return 0 }
        if let v = try? url.resourceValues(forKeys: keys), v.isRegularFile == true { return Int64(v.fileAllocatedSize ?? 0) }
        guard let e = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys)) else { return 0 }
        var n: Int64 = 0
        for case let p as URL in e {
            guard let v = try? p.resourceValues(forKeys: keys) else { continue }
            if v.isSymbolicLink == true { e.skipDescendants(); continue }
            if v.isRegularFile == true { n += Int64(v.fileAllocatedSize ?? 0) }
        }
        return n
    }
    static func scan(_ input: URL, home: URL = FileManager.default.homeDirectoryForCurrentUser) throws -> ScanResult {
        let app = input.standardizedFileURL
        guard app.pathExtension.lowercased() == "app", let info = plist(app.appendingPathComponent("Contents/Info.plist")),
              let bid = info["CFBundleIdentifier"] as? String, bid.contains("."), !bid.contains("/"),
              !bid.hasPrefix("com.apple."), !isWithin(app.resolvingSymlinksInPath(), URL(fileURLWithPath: "/System")) else {
            throw CleanerError.message("请选择第三方 .app 应用。系统应用不支持卸载。")
        }
        guard (try? app.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink != true else {
            throw CleanerError.message("这是应用的符号链接，请选择原始应用。")
        }
        guard bid != "io.jlmac.AppSweep" else { throw CleanerError.message("不能在运行时卸载清理工具自身。") }
        let name = app.deletingPathExtension().lastPathComponent
        var notes = ["仅扫描当前用户的常见残留目录；系统服务、驱动、浏览器扩展及 Homebrew 工具不自动卸载。"]
        var ids: Set<String> = [bid]
        if let e = FileManager.default.enumerator(at: app.appendingPathComponent("Contents"), includingPropertiesForKeys: [.isSymbolicLinkKey]) {
            for case let p as URL in e {
                if (try? p.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true { e.skipDescendants(); continue }
                if ["app", "appex", "xpc"].contains(p.pathExtension), let id = identity(p), id.hasPrefix(bid + ".") { ids.insert(id) }
            }
        }
        var otherCopy = false
        for root in [URL(fileURLWithPath: "/Applications"), home.appendingPathComponent("Applications"), home.appendingPathComponent("Desktop")] {
            let entries = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
            for p in entries where p.pathExtension == "app" && p.resolvingSymlinksInPath().path != app.resolvingSymlinksInPath().path {
                if identity(p) == bid { otherCopy = true }
            }
        }
        if otherCopy { notes.append("发现同标识的其他应用副本，可能共用数据；所有残留默认不勾选。") }
        if bid == "com.anthropic.claudefordesktop" { notes.append("Claude 桌面数据可能包含工作区；不会扫描 ~/.claude 或独立 Claude Code 工具。") }
        var items = [CleanItem(url: app, category: "应用本体", reason: "你选择的应用", recommended: true, bytes: size(app))]
        var names: Set<String> = [name]
        for key in ["CFBundleName", "CFBundleDisplayName"] {
            if let n = info[key] as? String, n.count >= 4, !n.contains("/"), !n.contains("$") { names.insert(n) }
        }
        // These are explicit per-product names, never fuzzy vendor matches.
        let aliases = ["com.microsoft.VSCode": ["Code"], "com.anthropic.claudefordesktop": ["Claude"], "com.quark.desktop": ["Quark"], "com.github.xor-gate.syncthing-macosx": ["Syncthing"]]
        names.formUnion(aliases[bid] ?? [])
        for location in locations {
            let root = home.appendingPathComponent("Library/" + location)
            let entries: [URL]
            do { entries = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isSymbolicLinkKey]) }
            catch { if FileManager.default.fileExists(atPath: root.path) { notes.append("无法读取：~/Library/\(location)") }; continue }
            for p in entries {
                let filename = p.lastPathComponent
                let exact = ids.contains { id in [id, id + ".plist", id + ".binarycookies", id + ".savedState", id + ".ShipIt"].contains(filename) }
                let named = names.contains(filename) && ["Application Support", "Caches", "Logs"].contains(location)
                guard exact || named else { continue }
                guard (try? p.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink != true,
                      isWithin(p.resolvingSymlinksInPath(), root.resolvingSymlinksInPath()) else { notes.append("已跳过符号链接：\(p.path)"); continue }
                let container = ["Containers", "Application Scripts"].contains(location)
                items.append(CleanItem(url: p, category: location == "Caches" ? "缓存" : "配置与数据", reason: container ? "沙盒数据，请确认后勾选；可能需要系统权限" : exact ? "应用标识精确匹配" : "目录名称匹配，请确认数据归属", recommended: exact && !otherCopy && !container, bytes: size(p)))
            }
        }
        notes.append("名称匹配、沙盒容器和共享数据不会自动勾选或删除；未列出的文件不代表不存在。")
        return ScanResult(app: app, name: name, bundleID: bid, items: items, notes: notes)
    }
}

struct MoveRecord: Codable, Identifiable {
    var id: String { original }
    let original: String
    var trashed: String?
    var status: String
    var error: String?
}
struct Receipt: Codable, Identifiable {
    let id: String
    let name: String
    let date: Date
    var records: [MoveRecord]
}

final class HistoryStore {
    let root: URL
    let fm = FileManager.default
    init(root: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/io.jlmac.AppSweep/History")) { self.root = root }
    func save(_ receipt: Receipt) throws {
        try fm.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(receipt).write(to: root.appendingPathComponent(receipt.id + ".json"), options: .atomic)
    }
    func list() -> [Receipt] {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        return ((try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []).compactMap { p in
            guard p.pathExtension == "json", let data = try? Data(contentsOf: p) else { return nil }
            return try? decoder.decode(Receipt.self, from: data)
        }.sorted { $0.date > $1.date }
    }
    func trash(_ items: [CleanItem], name: String, mover: ((URL) throws -> URL)? = nil) throws -> Receipt {
        var receipt = Receipt(id: UUID().uuidString, name: name, date: Date(), records: items.map { MoveRecord(original: $0.url.path, status: "pending") })
        try save(receipt)
        for i in receipt.records.indices {
            let src = URL(fileURLWithPath: receipt.records[i].original)
            do {
                guard fm.fileExists(atPath: src.path), (try src.resourceValues(forKeys: [.isSymbolicLinkKey])).isSymbolicLink != true,
                      src.standardizedFileURL.path == src.resolvingSymlinksInPath().standardizedFileURL.path else {
                    throw CleanerError.message("文件已变化或路径包含链接，请重新扫描。")
                }
                let dest: URL
                if let mover { dest = try mover(src) }
                else {
                    var output: NSURL?
                    try fm.trashItem(at: src, resultingItemURL: &output)
                    guard let output else { throw CleanerError.message("已移动，但系统未返回废纸篓路径，请在 Finder 中查看。") }
                    dest = output as URL
                }
                receipt.records[i].trashed = dest.path; receipt.records[i].status = "moved"
            } catch { receipt.records[i].status = "failed"; receipt.records[i].error = error.localizedDescription }
            try save(receipt)
        }
        return receipt
    }
    func restore(_ input: Receipt) throws -> Receipt {
        var receipt = input
        for i in receipt.records.indices where receipt.records[i].status == "moved" {
            guard let path = receipt.records[i].trashed else { continue }
            let src = URL(fileURLWithPath: path), dest = URL(fileURLWithPath: receipt.records[i].original)
            do {
                guard !fm.fileExists(atPath: dest.path) else { throw CleanerError.message("原位置已有文件，未覆盖。") }
                guard dest.deletingLastPathComponent().standardizedFileURL.path == dest.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL.path else { throw CleanerError.message("原目录路径已变为链接，未恢复。") }
                try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fm.moveItem(at: src, to: dest)
                receipt.records[i].status = "restored"; receipt.records[i].error = nil
            } catch { receipt.records[i].error = error.localizedDescription }
            try save(receipt)
        }
        return receipt
    }
}
