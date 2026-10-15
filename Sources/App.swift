import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor final class CleanerModel: ObservableObject {
    @Published var result: ScanResult?
    @Published var selected = Set<String>()
    @Published var busy = false
    @Published var message = ""
    @Published var history: [Receipt] = []
    let store = HistoryStore()
    var chosen: [CleanItem] { result?.items.filter { selected.contains($0.id) } ?? [] }
    var total: String { ByteCountFormatter.string(fromByteCount: chosen.reduce(0) { $0 + $1.bytes }, countStyle: .file) }
    func pick() {
        let panel = NSOpenPanel()
        panel.title = "选择要卸载的应用"; panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { scan(url) }
    }
    func scan(_ url: URL) {
        guard !busy else { return }
        busy = true; message = "正在查找关联文件…"; result = nil; selected = []
        DispatchQueue.global(qos: .userInitiated).async {
            let outcome = Result { try Scanner.scan(url) }
            DispatchQueue.main.async {
                self.busy = false
                switch outcome {
                case .success(let r): self.result = r; self.selected = Set(r.items.filter(\.recommended).map(\.id)); self.message = "找到 \(r.items.count) 项。请检查勾选项，配置与数据可能包含账号和工作记录。"
                case .failure(let e): self.message = e.localizedDescription
                }
            }
        }
    }
    func trash() {
        guard let result, !chosen.isEmpty, !busy else { return }
        let running = NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == result.bundleID || app.bundleURL.map { Scanner.isWithin($0, result.app) } == true || app.executableURL.map { Scanner.isWithin($0, result.app) } == true
        }
        guard !running else { message = "\(result.name) 仍在运行，请先退出应用后再卸载。"; return }
        let alert = NSAlert(); alert.messageText = "将 \(chosen.count) 项移入废纸篓？"
        alert.informativeText = "应用：\(result.name)\n合计约 \(total)\n包括勾选的配置与数据。废纸篓清空前可从历史记录恢复。"
        alert.addButton(withTitle: "移入废纸篓"); alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        busy = true
        do {
            let receipt = try store.trash(chosen, name: result.name)
            let moved = receipt.records.filter { $0.status == "moved" }.count
            let failed = receipt.records.filter { $0.status == "failed" }
            message = "已移入废纸篓 \(moved) 项，未清空废纸篓。" + (failed.isEmpty ? "" : "\n\(failed.count) 项未完成：\(failed.first?.error ?? "请查看历史记录")")
            self.result = nil; selected = []; history = store.list()
        } catch { message = "操作未全部完成：" + error.localizedDescription; history = store.list() }
        busy = false
    }
    func restore(_ receipt: Receipt) {
        guard !busy else { return }
        busy = true
        do {
            let updated = try store.restore(receipt)
            let remaining = updated.records.filter { $0.status == "moved" }.count
            message = remaining == 0 ? "已恢复 \(receipt.name)，没有覆盖已有文件。" : "仍有 \(remaining) 项无法恢复：\(updated.records.first { $0.error != nil }?.error ?? "请查看记录")"
        } catch { message = error.localizedDescription }
        history = store.list(); busy = false
    }
}

struct CleanerView: View {
    @StateObject private var model = CleanerModel()
    @State private var tab = 0
    @State private var targeted = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: "shippingbox.and.arrow.backward.fill").font(.system(size: 34)).foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 3) {
                    Text("轻卸").font(.system(size: 27, weight: .bold))
                    Text("卸载应用，也照顾留下的文件。").foregroundStyle(.secondary)
                }
                Spacer()
                Picker("页面", selection: $tab) { Text("卸载应用").tag(0); Text("恢复记录").tag(1) }.pickerStyle(.segmented).frame(width: 220)
            }
            if tab == 0 {
                HStack {
                    Image(systemName: "arrow.down.app").font(.title).foregroundStyle(.teal)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.result?.name ?? "将应用拖到这里").font(.headline)
                        Text(model.result?.app.path ?? "也可以选择应用；支持已放入废纸篓的 .app 文件。").font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                    Spacer()
                    Button("选择应用…", action: model.pick).disabled(model.busy)
                }.padding(20).frame(maxWidth: .infinity).background(targeted ? Color.teal.opacity(0.15) : Color.teal.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.teal.opacity(targeted ? 0.7 : 0.2), style: StrokeStyle(lineWidth: 1, dash: [6])))
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: $targeted) { providers in
                    guard !model.busy, let p = providers.first else { return false }
                    _ = p.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                        guard let data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                        DispatchQueue.main.async { model.scan(url) }
                    }
                    return true
                }
                if let result = model.result {
                    HStack {
                        Text("关联文件").font(.headline)
                        Text(result.bundleID).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("仅选精确匹配") { model.selected = Set(result.items.filter(\.recommended).map(\.id)) }
                        Button("取消全选") { model.selected = [] }
                    }
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(result.items) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    Toggle("选择", isOn: Binding(get: { model.selected.contains(item.id) }, set: { if $0 { model.selected.insert(item.id) } else { model.selected.remove(item.id) } })).labelsHidden().toggleStyle(.checkbox)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.url.lastPathComponent).fontWeight(.medium)
                                        Text(item.url.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                                        Text(item.reason).font(.caption).foregroundStyle(item.recommended ? Color.secondary : Color.orange)
                                    }
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: item.bytes, countStyle: .file)).font(.caption).monospacedDigit()
                                    Button { NSWorkspace.shared.activateFileViewerSelecting([item.url]) } label: { Image(systemName: "folder") }.buttonStyle(.borderless).help("在 Finder 中查看")
                                }.padding(12)
                                Divider()
                            }
                        }
                    }.background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 4) { ForEach(result.notes, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) } }
                    HStack {
                        Text("已选 \(model.chosen.count) 项 · 约 \(model.total)").fontWeight(.medium)
                        Spacer()
                        Button("移入废纸篓…", action: model.trash).buttonStyle(.borderedProminent).tint(.teal).disabled(model.chosen.isEmpty || model.busy)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield").font(.system(size: 46)).foregroundStyle(.teal.opacity(0.65))
                        Text("先看清，再卸载").font(.title3).fontWeight(.semibold)
                        Text("按应用标识查找 · 名称匹配需手动勾选\n文件移入废纸篓 · 支持恢复 · 不自动清空")
                            .multilineTextAlignment(.center).foregroundStyle(.secondary).lineSpacing(6)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                if model.history.isEmpty { Text("还没有卸载记录。完成一次清理后，可在这里恢复。").foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity) }
                else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(model.history) { receipt in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        VStack(alignment: .leading) { Text(receipt.name).font(.headline); Text(receipt.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary) }
                                        Spacer()
                                        Button("查看清单") { NSWorkspace.shared.activateFileViewerSelecting([model.store.root.appendingPathComponent(receipt.id + ".json")]) }
                                        Button("恢复") { model.restore(receipt) }.disabled(model.busy || !receipt.records.contains { $0.status == "moved" })
                                    }
                                    ForEach(receipt.records) { record in
                                        HStack(alignment: .top) {
                                            Image(systemName: record.status == "restored" ? "arrow.uturn.backward.circle" : record.status == "moved" ? "trash" : "exclamationmark.circle")
                                            VStack(alignment: .leading) {
                                                Text(record.original).lineLimit(2).textSelection(.enabled)
                                                if let error = record.error { Text(error).foregroundStyle(.orange) }
                                            }
                                            Spacer()
                                            Text(["moved":"已移入", "restored":"已恢复", "failed":"未完成", "pending":"待核实"][record.status] ?? record.status)
                                        }.font(.caption).foregroundStyle(.secondary)
                                    }
                                }.padding().background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
            Divider()
            HStack(alignment: .top) {
                if model.busy { ProgressView().controlSize(.small) }
                Text(model.message.isEmpty ? "所有处理均在本机完成。大小为估算，清空废纸篓后才释放空间。" : model.message).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                Spacer()
            }.frame(minHeight: 28)
        }.padding(26).frame(minWidth: 780, minHeight: 650)
        .onAppear { model.history = model.store.list() }
        .onReceive(NotificationCenter.default.publisher(for: .openCleanerApp)) { note in
            if let url = note.object as? URL { tab = 0; model.scan(url) }
        }
    }
}

extension Notification.Name { static let openCleanerApp = Notification.Name("openCleanerApp") }
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { NSApp.activate(ignoringOtherApps: true) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func application(_ sender: NSApplication, open urls: [URL]) {
        if let url = urls.first { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { NotificationCenter.default.post(name: .openCleanerApp, object: url) } }
    }
}

@main struct AppSweep: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup("轻卸") { CleanerView() }
            .defaultSize(width: 900, height: 740)
            .commands { CommandGroup(replacing: .newItem) {} }
    }
}
