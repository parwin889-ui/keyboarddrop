import Cocoa
import CoreGraphics

var observedKeycodes: [Int64] = []
let lock = NSLock()

let listenCallback: CGEventTapCallBack = { _, type, event, _ in
    if type == .keyDown || type == .keyUp {
        lock.lock()
        observedKeycodes.append(event.getIntegerValueField(.keyboardEventKeycode))
        lock.unlock()
    }
    return Unmanaged.passRetained(event)
}

func postKey(_ keyCode: CGKeyCode, keyDown: Bool) {
    let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
    event?.post(tap: .cghidEventTap)
}

func fmt(_ codes: [Int64]) -> String {
    codes.map { String(format: "0x%02X", $0) }.joined(separator: ", ")
}

let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)

guard let listenTap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .tailAppendEventTap,
    options: .listenOnly,
    eventsOfInterest: mask,
    callback: listenCallback,
    userInfo: nil
) else {
    print("❌ 无法创建监听 tap")
    exit(1)
}

let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, listenTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
CGEvent.tapEnable(tap: listenTap, enable: true)

print("=== 自定义操作测试 ===\n")
print("配置: f5 → command: open -a 'Activity Monitor'\n")

// Check if Activity Monitor is already running
func isProcessRunning(_ name: String) -> Bool {
    let task = Process()
    task.launchPath = "/usr/bin/pgrep"
    task.arguments = ["-x", name]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    return task.terminationStatus == 0
}

let amWasRunning = isProcessRunning("Activity Monitor")
print("Activity Monitor 之前运行: \(amWasRunning)")

// Test: post F5 keyDown (0x60) — should be suppressed, not seen by listener
print("\n[测试] 发送 f5 (0x60) keyDown — 期望被拦截(监听 tap 收不到)")
observedKeycodes.removeAll()
postKey(0x60, keyDown: true)
postKey(0x60, keyDown: false)
usleep(500000)
CFRunLoopRunInMode(.defaultMode, 0.5, false)

lock.lock()
let result = observedKeycodes
lock.unlock()
print("  监听 tap 收到: [\(fmt(result))]")
let eventSuppressed = result.isEmpty || !result.contains(0x60)
print("  事件被抑制: \(eventSuppressed ? "✅ 是" : "❌ 否(事件未被拦截)")")

// Wait for Activity Monitor to launch
print("\n  等待 Activity Monitor 启动...")
var amLaunched = false
for _ in 0..<20 {
    usleep(500000)
    CFRunLoopRunInMode(.defaultMode, 0.1, false)
    if isProcessRunning("Activity Monitor") {
        amLaunched = true
        break
    }
}
print("  Activity Monitor 已启动: \(amLaunched ? "✅ 是" : "❌ 否")")

// Summary
print("\n=== 测试总结 ===")
let passed = (eventSuppressed ? 1 : 0) + (amLaunched ? 1 : 0)
print("\(passed)/2 通过")

// Kill Activity Monitor if we launched it
if amLaunched && !amWasRunning {
    let killTask = Process()
    killTask.launchPath = "/usr/bin/pkill"
    killTask.arguments = ["-x", "Activity Monitor"]
    try? killTask.run()
    killTask.waitUntilExit()
    print("(已关闭测试启动的 Activity Monitor)")
}

CGEvent.tapEnable(tap: listenTap, enable: false)
exit(passed == 2 ? 0 : 1)
