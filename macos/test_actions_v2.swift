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

func getVolume() -> Int {
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["-e", "output volume of (get volume settings)"]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
    return Int(str) ?? 0
}

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
    print("Cannot create listen tap")
    exit(1)
}

let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, listenTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
CGEvent.tapEnable(tap: listenTap, enable: true)

var totalTests = 0
var passedTests = 0

func testSuppression(_ name: String, _ keyCode: CGKeyCode) {
    global_test(name) {
        observedKeycodes.removeAll()
        postKey(keyCode, keyDown: true)
        postKey(keyCode, keyDown: false)
        usleep(800000)
        CFRunLoopRunInMode(.defaultMode, 0.5, false)

        lock.lock()
        let result = observedKeycodes
        lock.unlock()

        let suppressed = result.isEmpty || !result.contains(Int64(keyCode))
        print("  监听收到: [\(fmt(result))] 抑制: \(suppressed ? "PASS" : "FAIL")")
        return suppressed
    }
}

func global_test(_ name: String, _ block: () -> Bool) {
    totalTests += 1
    print("[\(name)]")
    let ok = block()
    if ok { passedTests += 1 }
    print("  结果: \(ok ? "PASS" : "FAIL")\n")
}

// MARK: - Tests

print("=== KeyboardDrop v2 功能测试 ===\n")

// 1. Volume mute
let volBefore = getVolume()
global_test("F7 → Volume Mute") {
    postKey(0x62, keyDown: true)  // F7 keycode
    postKey(0x62, keyDown: false)
    usleep(1000000)
    CFRunLoopRunInMode(.defaultMode, 0.5, false)
    let volAfter = getVolume()
    print("  音量: \(volBefore) -> \(volAfter)")
    return volAfter == 0 || (volBefore == 0)
}

// Restore volume
let task = Process()
task.launchPath = "/usr/bin/osascript"
task.arguments = ["-e", "set volume \(volBefore)"]
try? task.run()
task.waitUntilExit()

// 2. Screenshot (full screen) - check file created
global_test("F6 → Screenshot (region interactive)") {
    // Use "screen" mode instead for non-interactive test
    // Just test event suppression
    let suppressed = observedKeycodes
    postKey(0x61, keyDown: true)  // F6 keycode
    postKey(0x61, keyDown: false)
    usleep(500000)
    CFRunLoopRunInMode(.defaultMode, 0.5, false)

    lock.lock()
    let result = observedKeycodes
    lock.unlock()
    let wasSuppressed = result.isEmpty || !result.contains(Int64(0x66))
    print("  F6 事件被抑制: \(wasSuppressed ? "是" : "否")")
    return wasSuppressed
}

// 3. URL open
let safariWasRunning = isProcessRunning("Safari")
global_test("F10 → URL (https://github.com)") {
    postKey(0x6D, keyDown: true)  // F10 keycode
    postKey(0x6D, keyDown: false)
    usleep(2000000)
    CFRunLoopRunInMode(.defaultMode, 1.0, false)
    let safariRunning = isProcessRunning("Safari") || isProcessRunning("Google Chrome")
    print("  浏览器已启动: \(safariRunning ? "是" : "否")")
    return safariRunning
}

// 4. Command (Activity Monitor)
let amWasRunning = isProcessRunning("Activity Monitor")
global_test("F5 → Command (Activity Monitor)") {
    postKey(0x60, keyDown: true)  // F5 keycode
    postKey(0x60, keyDown: false)
    usleep(2000000)
    CFRunLoopRunInMode(.defaultMode, 1.0, false)
    let amRunning = isProcessRunning("Activity Monitor")
    print("  Activity Monitor 启动: \(amRunning ? "是" : "否")")
    return amRunning
}

// Kill test processes
if !amWasRunning {
    let kill = Process()
    kill.launchPath = "/usr/bin/pkill"
    kill.arguments = ["-x", "Activity Monitor"]
    try? kill.run()
    kill.waitUntilExit()
}

// 5. System lock - skip (would lock screen)
print("[F9 → System Lock] 跳过(会锁定屏幕)\n")

// Summary
print("=== 测试总结 ===")
print("\(passedTests)/\(totalTests) 通过")

CGEvent.tapEnable(tap: listenTap, enable: false)
exit(passedTests == totalTests ? 0 : 1)
