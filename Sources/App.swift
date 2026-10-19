// BridgEddy — abre a sessão de outro usuário deste Mac numa janela do
// Compartilhamento de Tela e desfaz tudo ao terminar.
// © 2026 Eddy Antonini — MIT License

import SwiftUI
import AppKit

// MARK: - App

@main
struct BridgEddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = Model.shared

    var body: some Scene {
        WindowGroup("BridgEddy") {
            ContentView()
                .environmentObject(model)
                .frame(width: 420)
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        Model.shared.teardown()
    }
}

func appIcon(_ size: CGFloat) -> some View {
    Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .frame(width: size, height: size)
}

// MARK: - Interface

struct ContentView: View {
    @EnvironmentObject var m: Model
    @State private var showSupport = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                appIcon(40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("BridgEddy").font(.title2.bold())
                    Text(L("appSubtitle"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            switch m.phase {
            case .idle:
                idleView
            case .preparing:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(m.status)
                }
            case .connected:
                connectedView
            }

            if let e = m.error {
                Text(e)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                Link("Eddy Antonini", destination: URL(string: "https://eddyantonini.com.br")!)
                    .font(.caption)
                Spacer()
                Button {
                    showSupport = true
                } label: {
                    Label(L("supportBtn"), systemImage: "heart.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.pink)
                .font(.caption)
            }
        }
        .padding(20)
        .sheet(isPresented: $showSupport) {
            VStack(alignment: .trailing, spacing: 0) {
                SupportView()
                Button(L("close")) { showSupport = false }
                    .keyboardShortcut(.cancelAction)
                    .padding([.trailing, .bottom], 22)
            }
        }
        .onAppear {
            m.load()
            DispatchQueue.main.async { m.offerCleanup() }
        }
    }

    @ViewBuilder private var idleView: some View {
        if m.users.isEmpty {
            Text(L("noUsers")).foregroundStyle(.secondary)
        } else {
            Picker(L("user"), selection: $m.selected) {
                ForEach(m.users) { u in Text(u.label).tag(u.name) }
            }
            HStack {
                if !m.status.isEmpty {
                    Text(m.status).font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Button(L("connect")) { m.connect() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(m.selected.isEmpty)
            }
        }
    }

    @ViewBuilder private var connectedView: some View {
        Label(L("bridgeOpen"), systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        Text(.init(Lf("loginHint", m.connectedUser)))
            .font(.callout)
            .fixedSize(horizontal: false, vertical: true)

        if m.showLocalhostHelp {
            VStack(alignment: .leading, spacing: 8) {
                Label(L("localhostTitle"), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout.weight(.semibold))
                Text(L("localhostText"))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                Button(L("restartSharing")) { m.restartScreenSharing() }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
        } else {
            Text(L("closeHint"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        HStack {
            Spacer()
            Button(L("disconnect")) { m.finish() }
        }
    }
}

// MARK: - Lógica

struct LocalUser: Identifiable, Hashable {
    let name: String
    let realName: String
    var id: String { name }
    var label: String { realName.isEmpty || realName == name ? name : "\(realName) (\(name))" }
}

final class Model: ObservableObject {
    static let shared = Model()

    enum Phase { case idle, preparing, connected }

    @Published var users: [LocalUser] = []
    @Published var selected = ""
    @Published var phase: Phase = .idle
    @Published var status = ""
    @Published var error: String?
    @Published var connectedUser = ""
    @Published var showLocalhostHelp = false

    private var tunnel: Process?
    private var tempKey: TempKey?
    private var doneFile: URL?          // quando existir, o vigia (root) desliga o que o app ligou
    private var monitor: Timer?
    private var firstSeen: Date?
    private var idleTicks = 0
    private var waitingSince = Date()
    private var port: UInt16 = 0

    /// Uma conexão que cai antes disso é tratada como falha (ex.: "não permitido no localhost").
    private let shortSession: TimeInterval = 45

    func load() {
        Sys.cleanLeftovers()
        users = Sys.otherUsers()
        if !users.contains(where: { $0.name == selected }) {
            selected = users.first?.name ?? ""
        }
    }

    // 1. Liga só os serviços que estiverem desligados (uma senha de admin)
    func connect() {
        guard phase == .idle, !selected.isEmpty else { return }
        error = nil
        status = L("preparing")
        connectedUser = selected
        showLocalhostHelp = false
        phase = .preparing

        let needSSH = !Sys.portOpen(22)
        let needVNC = !Sys.portOpen(5900)

        if needSSH || needVNC {
            status = L("enablingServices")
            let done = FileManager.default.temporaryDirectory
                .appendingPathComponent("bridgeddy-\(UUID().uuidString).done")
            do {
                try Sys.enableServicesTemporarily(ssh: needSSH, screenSharing: needVNC,
                                                  doneFile: done.path, pid: getpid())
                doneFile = done
            } catch {
                fail(Lf("errServices", error.localizedDescription))
                return
            }
        }
        waitForServices(deadline: Date().addingTimeInterval(8))
    }

    private func waitForServices(deadline: Date) {
        guard phase == .preparing else { return }
        let ssh = Sys.portOpen(22), vnc = Sys.portOpen(5900)
        if ssh && vnc { startTunnel(); return }
        if Date() > deadline {
            Sys.openSharingSettings()
            var missing: [String] = []
            if !vnc { missing.append(L("svcScreen")) }
            if !ssh { missing.append(L("svcRemote")) }
            fail(Lf("errBlocked", missing.joined(separator: " + ")))
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.waitForServices(deadline: deadline) }
    }

    // 2. Chave temporária + túnel SSH
    private func startTunnel() {
        status = L("openingTunnel")
        guard let p = (UInt16(5901)...UInt16(5910)).first(where: { !Sys.portOpen($0) }) else {
            fail(L("errNoPort"))
            return
        }
        port = p
        let key: TempKey
        do { key = try TempKey.create() } catch {
            fail(Lf("errKey", error.localizedDescription))
            return
        }
        tempKey = key

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        proc.arguments = [
            "-N", "-L", "\(p):localhost:5900",
            "-i", key.path,
            "-o", "IdentitiesOnly=yes",
            "-o", "BatchMode=yes",
            "-o", "ExitOnForwardFailure=yes",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "ServerAliveInterval=15",
            "localhost",
        ]
        let errPipe = Pipe()
        proc.standardError = errPipe
        proc.standardOutput = FileHandle.nullDevice
        proc.terminationHandler = { [weak self] pr in
            let msg = String(decoding: errPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            DispatchQueue.main.async {
                guard let self, self.tunnel === pr, self.phase != .idle else { return }
                self.fail(Lf("errTunnelClosed", msg.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        do { try proc.run() } catch {
            fail(Lf("errSSH", error.localizedDescription))
            return
        }
        tunnel = proc
        waitForTunnel(deadline: Date().addingTimeInterval(10))
    }

    private func waitForTunnel(deadline: Date) {
        guard phase == .preparing, tunnel != nil else { return }
        if Sys.portOpen(port) {
            phase = .connected
            status = ""
            openWindow()
            startMonitor()
            return
        }
        if Date() > deadline { fail(L("errTunnelTimeout")); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.waitForTunnel(deadline: deadline) }
    }

    /// 3. Abre a janela — endereço puro, sem usuário/senha (é o que o macOS aceita).
    private func openWindow() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(connectedUser, forType: .string)
        if let url = URL(string: "vnc://localhost:\(port)") { NSWorkspace.shared.open(url) }
    }

    // 4. Vigia: quando a janela fecha, desfaz tudo
    private func startMonitor() {
        firstSeen = nil
        idleTicks = 0
        waitingSince = Date()
        monitor?.invalidate()
        let watchedPort = port
        monitor = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            DispatchQueue.global().async {
                let n = Sys.establishedConnections(port: watchedPort)
                DispatchQueue.main.async { self?.tick(connections: n) }
            }
        }
    }

    private func tick(connections n: Int) {
        guard phase == .connected else { return }
        if n > 0 {
            if firstSeen == nil { firstSeen = Date() }
            idleTicks = 0
            return
        }
        guard let seen = firstSeen else {
            if Date().timeIntervalSince(waitingSince) > 180 { finish(message: L("noConnection")) }
            return
        }
        idleTicks += 1
        guard idleTicks >= 2 else { return }

        if Date().timeIntervalSince(seen) < shortSession {
            // Caiu logo depois do login: mantém a ponte e oferece a correção.
            showLocalhostHelp = true
            firstSeen = nil
            idleTicks = 0
            waitingSince = Date()
        } else {
            finish()
        }
    }

    /// Equivale a desligar e religar o Compartilhar Tela nos Ajustes.
    func restartScreenSharing() {
        do {
            try Sys.runAsAdmin("launchctl kickstart -k system/com.apple.screensharing",
                               prompt: L("adminPromptRestart"))
        } catch {
            self.error = Lf("errRestart", error.localizedDescription)
            return
        }
        showLocalhostHelp = false
        waitingSince = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, self.phase == .connected else { return }
            self.openWindow()
        }
    }

    func finish(message: String? = nil) {
        teardown()
        phase = .idle
        showLocalhostHelp = false
        status = message ?? L("done")
    }

    /// Fecha o túnel, apaga a chave e avisa o vigia para restaurar os serviços.
    func teardown() {
        monitor?.invalidate()
        monitor = nil
        if let t = tunnel {
            tunnel = nil
            if t.isRunning { t.terminate() }
        }
        tempKey?.remove()
        tempKey = nil
        if let done = doneFile {
            FileManager.default.createFile(atPath: done.path, contents: nil)
            doneFile = nil
        }
    }

    private func fail(_ msg: String) {
        teardown()
        phase = .idle
        status = ""
        showLocalhostHelp = false
        error = msg
    }

    // Limpeza da configuração antiga (scripts manuais), oferecida uma vez
    func offerCleanup() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "cleanupOffered") else { return }
        defaults.set(true, forKey: "cleanupOffered")

        if Sys.hasOldSetup() {
            let a = NSAlert()
            a.messageText = L("oldSetupTitle")
            a.informativeText = L("oldSetupText")
            a.addButton(withTitle: L("remove"))
            a.addButton(withTitle: L("keep"))
            if a.runModal() == .alertFirstButtonReturn {
                do { try Sys.removeOldSetup() } catch {
                    self.error = Lf("errOldSetup", error.localizedDescription)
                }
            }
        }

        if Sys.portOpen(22) {
            let a = NSAlert()
            a.messageText = L("sshOffTitle")
            a.informativeText = L("sshOffText")
            a.addButton(withTitle: L("turnOff"))
            a.addButton(withTitle: L("keepOn"))
            if a.runModal() == .alertFirstButtonReturn {
                do {
                    try Sys.runAsAdmin(
                        "launchctl bootout system/com.openssh.sshd 2>/dev/null; launchctl disable system/com.openssh.sshd",
                        prompt: L("adminPromptSSHOff")
                    )
                } catch {
                    self.error = Lf("errSSHOff", error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Chave temporária

struct TempKey {
    static let tag = "bridgeddy-temp-"
    let path: String
    let comment: String

    static func create() throws -> TempKey {
        let id = UUID().uuidString
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("bridgeddy-key-\(id)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let path = dir.appendingPathComponent("id_ed25519").path
        let comment = tag + id
        let gen = Process()
        gen.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
        gen.arguments = ["-q", "-t", "ed25519", "-N", "", "-C", comment, "-f", path]
        gen.standardOutput = FileHandle.nullDevice
        gen.standardError = FileHandle.nullDevice
        try gen.run()
        gen.waitUntilExit()
        guard gen.terminationStatus == 0,
              let pub = try? String(contentsOfFile: path + ".pub", encoding: .utf8) else {
            throw NSError(domain: "BridgEddy", code: 3, userInfo: [NSLocalizedDescriptionKey: "ssh-keygen"])
        }
        // Só do próprio Mac, só para a porta do Compartilhamento de Tela.
        let line = #"restrict,port-forwarding,permitopen="localhost:5900",from="127.0.0.1,::1" "#
            + pub.trimmingCharacters(in: .whitespacesAndNewlines)
        try Sys.appendAuthorizedKey(line)
        return TempKey(path: path, comment: comment)
    }

    func remove() {
        Sys.removeAuthorizedKeys(containing: comment)
        try? FileManager.default.removeItem(atPath: (path as NSString).deletingLastPathComponent)
    }
}
