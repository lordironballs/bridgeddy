// BridgEddy — acesso ao sistema (usuários, portas, serviços, authorized_keys)
// © 2026 Eddy Antonini — MIT License

import Foundation
import AppKit
import Darwin

enum Sys {
    static func run(_ path: String, _ args: [String]) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }

    /// Usuários "de verdade" (UID >= 501), exceto o atual.
    static func otherUsers() -> [LocalUser] {
        let me = NSUserName()
        let out = run("/usr/bin/dscl", [".", "-list", "/Users", "UniqueID"])
        var result: [LocalUser] = []
        for line in out.split(separator: "\n") {
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard parts.count >= 2, let uid = Int(parts.last!), uid >= 501 else { continue }
            let name = String(parts.first!)
            guard name != me, !name.hasPrefix("_") else { continue }
            result.append(LocalUser(name: name, realName: realName(of: name)))
        }
        return result.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    static func realName(of user: String) -> String {
        let out = run("/usr/bin/dscl", [".", "-read", "/Users/\(user)", "RealName"])
        let cleaned = out.replacingOccurrences(of: "RealName:", with: "")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n").first?
            .trimmingCharacters(in: .whitespaces) ?? ""
    }

    /// Testa se há algo escutando numa porta local.
    static func portOpen(_ port: UInt16) -> Bool {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { Darwin.close(fd) }
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        let r = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return r == 0
    }

    /// Conexões ativas na porta do túnel (janela do Compartilhamento de Tela aberta).
    static func establishedConnections(port: UInt16) -> Int {
        let out = run("/usr/sbin/lsof", ["-nP", "-iTCP:\(port)", "-sTCP:ESTABLISHED"])
        return max(out.split(separator: "\n").count - 1, 0)
    }

    /// Pede a senha de administrador com a janela padrão do macOS.
    static func runAsAdmin(_ script: String, prompt: String) throws {
        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        }
        let source = "do shell script \"\(esc(script))\" with prompt \"\(esc(prompt))\" with administrator privileges"
        var err: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&err)
        if let err {
            let msg = err[NSAppleScript.errorMessage] as? String ?? "?"
            throw NSError(domain: "BridgEddy", code: 2, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }

    /// Liga o que estiver desligado e deixa um vigia (root) que desliga de novo
    /// quando o arquivo `doneFile` aparecer ou quando o app fechar.
    /// Assim a senha de administrador é pedida uma vez só.
    static func enableServicesTemporarily(ssh: Bool, screenSharing: Bool, doneFile: String, pid: Int32) throws {
        var on: [String] = []
        var off: [String] = []
        if ssh {
            on.append("launchctl enable system/com.openssh.sshd; launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null")
            off.append("launchctl bootout system/com.openssh.sshd 2>/dev/null; launchctl disable system/com.openssh.sshd")
        }
        if screenSharing {
            on.append("launchctl enable system/com.apple.screensharing; launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || launchctl kickstart -k system/com.apple.screensharing 2>/dev/null")
            off.append("launchctl bootout system/com.apple.screensharing 2>/dev/null; launchctl disable system/com.apple.screensharing")
        }
        let watcher = "while kill -0 \(pid) 2>/dev/null && [ ! -e '\(doneFile)' ]; do sleep 2; done; "
            + off.joined(separator: "; ")
            + "; rm -f '\(doneFile)'"
        let script = on.joined(separator: "; ")
            + "; nohup /bin/bash -c \"\(watcher)\" >/dev/null 2>&1 &"
        try runAsAdmin(script, prompt: L("adminPromptEnable"))
    }

    static func openSharingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Sharing-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: authorized_keys

    static var sshDir: String { NSHomeDirectory() + "/.ssh" }
    static var authorizedKeys: String { sshDir + "/authorized_keys" }

    static func appendAuthorizedKey(_ line: String) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: sshDir) {
            try fm.createDirectory(atPath: sshDir, withIntermediateDirectories: true,
                                   attributes: [.posixPermissions: 0o700])
        }
        var current = (try? String(contentsOfFile: authorizedKeys, encoding: .utf8)) ?? ""
        if !current.isEmpty && !current.hasSuffix("\n") { current += "\n" }
        current += line + "\n"
        try current.write(toFile: authorizedKeys, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: authorizedKeys)
    }

    static func removeAuthorizedKeys(containing marker: String) {
        guard let s = try? String(contentsOfFile: authorizedKeys, encoding: .utf8), s.contains(marker) else { return }
        let kept = s.components(separatedBy: "\n").filter { !$0.contains(marker) }
        try? kept.joined(separator: "\n").write(toFile: authorizedKeys, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: authorizedKeys)
    }

    /// Restos de uma sessão que terminou mal (app fechado à força, Mac desligado),
    /// inclusive da versão de testes que se chamava "Ponte".
    static func cleanLeftovers() {
        for marker in ["bridgeddy-key-", "ponte-key-"] {
            _ = run("/usr/bin/pkill", ["-f", marker])
        }
        removeAuthorizedKeys(containing: TempKey.tag)
        removeAuthorizedKeys(containing: "ponte-temp-")
        let tmp = FileManager.default.temporaryDirectory
        if let items = try? FileManager.default.contentsOfDirectory(atPath: tmp.path) {
            for i in items where i.hasPrefix("bridgeddy-key-") || i.hasPrefix("ponte-key-") {
                try? FileManager.default.removeItem(at: tmp.appendingPathComponent(i))
            }
        }
    }

    // MARK: Configuração manual antiga (chave fixa "tunel-vnc-local")

    static var oldKey: String { sshDir + "/id_ed25519_tunel_vnc" }

    static func hasOldSetup() -> Bool {
        if FileManager.default.fileExists(atPath: oldKey) { return true }
        let s = (try? String(contentsOfFile: authorizedKeys, encoding: .utf8)) ?? ""
        return s.contains("tunel-vnc-local")
    }

    static func removeOldSetup() throws {
        let fm = FileManager.default
        for f in [oldKey, oldKey + ".pub"] where fm.fileExists(atPath: f) {
            try fm.removeItem(atPath: f)
        }
        removeAuthorizedKeys(containing: "tunel-vnc-local")
    }
}
