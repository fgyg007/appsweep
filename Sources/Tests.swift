import Foundation

@main struct Tests {
    static func main() throws {
        let fm = FileManager.default
        var root = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("build/AppSweep-test-" + UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        root = root.resolvingSymlinksInPath()
        defer { try? fm.removeItem(at: root) }
        let home = root.appendingPathComponent("home")
        func file(_ path: String) throws -> URL {
            let p = home.appendingPathComponent(path)
            try fm.createDirectory(at: p.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("fixture".utf8).write(to: p)
            return p
        }
        func app(_ path: String, id: String) throws -> URL {
            let p = home.appendingPathComponent(path)
            try fm.createDirectory(at: p.appendingPathComponent("Contents"), withIntermediateDirectories: true)
            let d = try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier":id, "CFBundleName":"Demo"], format: .xml, options: 0)
            try d.write(to: p.appendingPathComponent("Contents/Info.plist"))
            return p
        }
        func check(_ value: @autoclosure () -> Bool, _ name: String) throws {
            guard value() else { throw CleanerError.message("FAIL: " + name) }; print("PASS: " + name)
        }
        let a = try app("Applications/Demo.app", id: "org.example.demo")
        let pref = try file("Library/Preferences/org.example.demo.plist")
        let cache = try file("Library/Caches/org.example.demo/data")
        let named = try file("Library/Application Support/Demo/account")
        let unrelated = try file("Library/Application Support/org.example.other/account")
        let shared = try file("Library/Group Containers/TEAM.org.example.demo/account")
        let container = try file("Library/Containers/org.example.demo/data")
        let alias = home.appendingPathComponent("Library/Logs/org.example.demo")
        try fm.createDirectory(at: alias.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.createSymbolicLink(at: alias, withDestinationURL: unrelated.deletingLastPathComponent())
        let scan = try Scanner.scan(a, home: home)
        try check(scan.items.contains { $0.url.path == pref.path && $0.recommended }, "exact identifier preference selected")
        try check(scan.items.contains { $0.url.path == cache.deletingLastPathComponent().path && $0.recommended }, "exact cache selected")
        try check(scan.items.contains { $0.url.path == named.deletingLastPathComponent().path && !$0.recommended }, "name match requires review")
        try check(scan.items.contains { $0.url.path == container.deletingLastPathComponent().path && !$0.recommended }, "sandbox container requires review")
        try check(!scan.items.contains { $0.url.path == alias.path }, "symbolic link excluded")
        try check(!scan.items.contains { Scanner.isWithin(unrelated, $0.url) || Scanner.isWithin(shared, $0.url) }, "unrelated and shared data excluded")
        _ = try app("Desktop/Demo copy.app", id: "org.example.demo")
        let copies = try Scanner.scan(a, home: home)
        try check(copies.items.filter(\.recommended).count == 1, "duplicate app copies preserve residuals by default")
        let systemApp = try app("Applications/System.app", id: "com.apple.fake")
        var blocked = false
        do { _ = try Scanner.scan(systemApp, home: home) } catch { blocked = true }
        try check(blocked, "Apple application rejected")
        let store = HistoryStore(root: root.appendingPathComponent("history"))
        let trash = root.appendingPathComponent("trash")
        try fm.createDirectory(at: trash, withIntermediateDirectories: true)
        let items = scan.items.filter { $0.url.path == pref.path || $0.url.path == cache.deletingLastPathComponent().path }
        let receipt = try store.trash(items, name: "Demo", mover: { src in
            let dst = trash.appendingPathComponent(UUID().uuidString)
            try fm.moveItem(at: src, to: dst); return dst
        })
        try check(receipt.records.allSatisfy { $0.status == "moved" }, "trash succeeds and records destination")
        try check(store.list().count == 1, "receipt persists and loads")
        _ = try file("Library/Preferences/org.example.demo.plist")
        let partial = try store.restore(receipt)
        try check(partial.records.contains { $0.original == pref.path && $0.error != nil && $0.status == "moved" }, "restore never overwrites existing files")
        try fm.removeItem(at: pref)
        let restored = try store.restore(partial)
        try check(restored.records.allSatisfy { $0.status == "restored" }, "restore retries conflict and restores all files")
        try check(fm.fileExists(atPath: pref.path) && fm.fileExists(atPath: cache.path), "restored files exist")
        let fail = try store.trash(items, name: "Denied", mover: { _ in throw CleanerError.message("permission denied fixture") })
        try check(fail.records.allSatisfy { $0.status == "failed" } && fm.fileExists(atPath: pref.path), "failed moves retain source and record error")
        let real = try store.trash(items, name: "Disposable integration fixture")
        try check(real.records.allSatisfy { $0.status == "moved" && $0.trashed != nil }, "macOS real Trash API returns recoverable paths")
        let realRestored = try store.restore(real)
        try check(realRestored.records.allSatisfy { $0.status == "restored" }, "real Trash round trip restores fixture files")
        print("All tests passed; only temporary fixture files were changed.")
    }
}
