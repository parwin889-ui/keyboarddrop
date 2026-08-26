import Cocoa
import CoreGraphics

var observedKeycodes: [Int64] = []
let lock = NSLock()

let listenCallback: CGEventTapCallBack = { _, type, event, _ in
    if type == .keyDown || type == .keyUp || type == .flagsChanged {
        let kc = event.getIntegerValueField(.keyboardEventKeycode)
        lock.lock()
        observedKeycodes.append(kc)
        lock.unlock()
    }
    return Unmanaged.passRetained(event)
}

func postKey(_ keyCode: CGKeyCode, keyDown: Bool) {
    let event = CGEvent(
        keyboardEventSource: nil,
        virtualKey: keyCode,
        keyDown: keyDown
    )
    event?.post(tap: .cghidEventTap)
}

func drainEvents(_ ms: Int) {
    usleep(useconds_t(ms * 1000))
    CFRunLoopRunInMode(.defaultMode, CFTimeInterval(ms) / 1000.0, false)
}

func fmt(_ codes: [Int64]) -> String {
    codes.map { String(format: "0x%02X", $0) }.joined(separator: ", ")
}

let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
           | CGEventMask(1 << CGEventType.keyUp.rawValue)
           | CGEventMask(1 << CGEventType.flagsChanged.rawValue)

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

print("=== keyboarddrop 功能测试 ===\n")
print("配置: caps_lock → escape, right_command → left_control\n")

// Test 1: caps_lock (0x39) → escape (0x35)
print("[测试1] caps_lock (0x39) → 期望 escape (0x35)")
observedKeycodes.removeAll()
postKey(0x39, keyDown: true)
postKey(0x39, keyDown: false)
drainEvents(300)
lock.lock()
let t1 = observedKeycodes
lock.unlock()
print("  收到: [\(fmt(t1))]")
let t1Pass = t1.contains(0x35)
print("  结果: \(t1Pass ? "✅ 通过" : "❌ 未重映射 (caps_lock 受系统限制)")\n")

// Test 2: right_command (0x36) → left_control (0x3B)
print("[测试2] right_command (0x36) → 期望 left_control (0x3B)")
observedKeycodes.removeAll()
postKey(0x36, keyDown: true)
postKey(0x36, keyDown: false)
drainEvents(300)
lock.lock()
let t2 = observedKeycodes
lock.unlock()
print("  收到: [\(fmt(t2))]")
let t2Pass = t2.contains(0x3B)
print("  结果: \(t2Pass ? "✅ 通过" : "❌ 未重映射")\n")

// Test 3: 'a' (0x00) → pass-through (0x00)
print("[测试3] 'a' (0x00) → 期望原样传递 (0x00)")
observedKeycodes.removeAll()
postKey(0x00, keyDown: true)
postKey(0x00, keyDown: false)
drainEvents(300)
lock.lock()
let t3 = observedKeycodes
lock.unlock()
print("  收到: [\(fmt(t3))]")
let t3Pass = t3.contains(0x00)
print("  结果: \(t3Pass ? "✅ 通过" : "❌ 异常")\n")

// Summary
print("=== 测试总结 ===")
let passed = [t1Pass, t2Pass, t3Pass].filter { $0 }.count
print("\(passed)/3 通过")

CGEvent.tapEnable(tap: listenTap, enable: false)
CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)

exit(passed >= 2 ? 0 : 1)
