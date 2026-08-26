import Cocoa
import CoreGraphics

enum KeyAction: Equatable {
    case remap(CGKeyCode)
    case app(String)
    case command(String)
    case ssh(String)
    case file(String)
    case script(String)
    case screenshot(String)
    case url(String)
    case volume(String)
    case media(String)
    case text(String)
    case system(String)

    var isRemap: Bool {
        if case .remap = self { return true }
        return false
    }

    var description: String {
        switch self {
        case .remap(let code):
            let name = KeyMap.name(for: code) ?? String(format: "0x%02X", code)
            return "-> \(name)"
        case .app(let path):
            let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
            return "-> App: \(name)"
        case .command(let cmd):
            let short = cmd.count > 30 ? String(cmd.prefix(27)) + "..." : cmd
            return "-> Cmd: \(short)"
        case .ssh(let host):
            return "-> SSH: \(host)"
        case .file(let path):
            return "-> File: \((path as NSString).lastPathComponent)"
        case .script(let path):
            return "-> Script: \((path as NSString).lastPathComponent)"
        case .screenshot(let mode):
            return "-> Screenshot: \(mode)"
        case .url(let u):
            return "-> URL: \(u)"
        case .volume(let action):
            return "-> Volume: \(action)"
        case .media(let action):
            return "-> Media: \(action)"
        case .text(let t):
            let short = t.count > 20 ? String(t.prefix(17)) + "..." : t
            return "-> Text: \(short)"
        case .system(let action):
            return "-> System: \(action)"
        }
    }

    func execute() {
        switch self {
        case .remap:
            break

        case .app(let path):
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init())

        case .command(let cmd):
            runShell(cmd)

        case .ssh(let host):
            runAppleScript("tell application \"Terminal\"\nactivate\ndo script \"ssh \(host)\"\nend tell")

        case .file(let path):
            NSWorkspace.shared.open(URL(fileURLWithPath: path))

        case .script(let path):
            let task = Process()
            task.launchPath = "/bin/sh"
            task.arguments = [path]
            try? task.run()

        case .screenshot(let mode):
            let timestamp = formattedTimestamp()
            let desktop = NSHomeDirectory() + "/Desktop"
            let filename = "\(desktop)/Screenshot_\(timestamp).png"
            switch mode.lowercased() {
            case "region", "selection":
                runShell("screencapture -i '\(filename)'")
            case "window":
                runShell("screencapture -w '\(filename)'")
            case "clipboard", "clip":
                runShell("screencapture -c")
            default:
                runShell("screencapture '\(filename)'")
            }

        case .url(let urlString):
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }

        case .volume(let action):
            switch action.lowercased() {
            case "up":
                runAppleScript("set volume output volume ((output volume of (get volume settings)) + 10)")
            case "down":
                runAppleScript("set volume output volume ((output volume of (get volume settings)) - 10)")
            case "mute":
                runAppleScript("set volume with output muted")
            case "unmute":
                runAppleScript("set volume without output muted")
            default:
                if let level = Int(action) {
                    runAppleScript("set volume \(max(0, min(100, level)))")
                }
            }

        case .media(let action):
            switch action.lowercased() {
            case "play", "playpause", "pause":
                runAppleScript("tell application \"Music\" to playpause")
            case "next", "next_track":
                runAppleScript("tell application \"Music\" to next track")
            case "prev", "previous", "prev_track":
                runAppleScript("tell application \"Music\" to previous track")
            default:
                break
            }

        case .text(let t):
            DispatchQueue.global(qos: .userInitiated).async {
                for char in t {
                    if let keyCode = charToKeyCode(char) {
                        let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
                        let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
                        down?.post(tap: .cghidEventTap)
                        up?.post(tap: .cghidEventTap)
                        usleep(20000)
                    }
                }
            }

        case .system(let action):
            switch action.lowercased() {
            case "sleep":
                runShell("pmset sleepnow")
            case "lock":
                runShell("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend")
            case "restart":
                runAppleScript("tell application \"System Events\" to restart")
            case "shutdown":
                runAppleScript("tell application \"System Events\" to shut down")
            case "logout":
                runShell("kill -TERM $(pgrep -u $USER -x loginwindow)")
            default:
                break
            }
        }
    }

    static func fromConfig(_ value: Any) -> KeyAction? {
        if let str = value as? String {
            guard let code = KeyMap.code(for: str) else {
                print("  [warning] unknown target key: \(str)")
                return nil
            }
            return .remap(code)
        }

        guard let dict = value as? [String: Any],
              let type = dict["type"] as? String,
              let target = dict["target"] as? String else {
            print("  [warning] invalid action config, expected {\"type\": \"...\", \"target\": \"...\"}")
            return nil
        }

        switch type.lowercased() {
        case "remap", "key":
            guard let code = KeyMap.code(for: target) else {
                print("  [warning] unknown target key: \(target)")
                return nil
            }
            return .remap(code)
        case "app":       return .app(target)
        case "command", "cmd": return .command(target)
        case "ssh":       return .ssh(target)
        case "file":      return .file(target)
        case "script":    return .script(target)
        case "screenshot", "screen": return .screenshot(target)
        case "url", "web": return .url(target)
        case "volume":    return .volume(target)
        case "media":     return .media(target)
        case "text", "type": return .text(target)
        case "system":    return .system(target)
        default:
            print("  [warning] unknown action type: \(type)")
            return nil
        }
    }
}

// MARK: - Helpers

private func runShell(_ cmd: String) {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", cmd]
    try? task.run()
}

private func runAppleScript(_ source: String) {
    if let script = NSAppleScript(source: source) {
        var error: NSDictionary?
        script.executeAndReturnError(&error)
    }
}

private func formattedTimestamp() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    return f.string(from: Date())
}

private func charToKeyCode(_ char: Character) -> CGKeyCode? {
    let lower = String(char).lowercased()
    guard let first = lower.first else { return nil }
    return KeyMap.code(for: String(first))
}
