import Cocoa
import CoreGraphics

var observed: [Int64] = []
let lock = NSLock()

let cb: CGEventTapCallBack = { _, type, event, _ in
    if type == .keyDown || type == .keyUp {
        lock.lock()
        observed.append(event.getIntegerValueField(.keyboardEventKeycode))
        lock.unlock()
    }
    return Unmanaged.passRetained(event)
}

func postKey(_ kc: CGKeyCode, _ down: Bool) {
    CGEvent(keyboardEventSource: nil, virtualKey: kc, keyDown: down)?.post(tap: .cghidEventTap)
}

let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)

guard let tap = CGEvent.tapCreate(
    tap: .cghidEventTap, place: .tailAppendEventTap,
    options: .listenOnly, eventsOfInterest: mask,
    callback: cb, userInfo: nil
) else { exit(1) }

let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

print("=== 自定义映射测试 ===")
print("tab (0x30) → f1 (0x7A)\n")

// Test tab → f1
observed.removeAll()
postKey(0x30, true)  // tab down
postKey(0x30, false) // tab up
usleep(300000)
CFRunLoopRunInMode(.defaultMode, 0.3, false)

lock.lock()
let result = observed
lock.unlock()

print("发送: tab (0x30)")
print("收到: \(result.map { String(format: "0x%02X", $0) })")
print("结果: \(result.contains(0x7A) ? "✅ tab→f1 重映射成功" : "❌ 未重映射")")

CGEvent.tapEnable(tap: tap, enable: false)
exit(result.contains(0x7A) ? 0 : 1)
