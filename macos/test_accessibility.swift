import Cocoa
import ApplicationServices

// Test 1: Check if accessibility permission is granted
print("=== keyboarddrop 接入性测试 ===\n")

let trusted = AXIsProcessTrusted()
print("[1/3] AXIsProcessTrusted: \(trusted ? "✅ 已授权" : "❌ 未授权")")

if !trusted {
    print("\n⚠️  需要辅助功能权限。正在触发系统授权弹窗...")
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    _ = AXIsProcessTrustedWithOptions(options)
    print("请在「系统设置 → 隐私与安全性 → 辅助功能」中添加并启用 keyboarddrop")
    print("授权后重新运行此测试脚本。\n")
    exit(1)
}

// Test 2: Try to create an event tap (the actual integration test)
print("[2/3] 尝试创建 CGEventTap...")

let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
                   | CGEventMask(1 << CGEventType.keyUp.rawValue)
                   | CGEventMask(1 << CGEventType.flagsChanged.rawValue)

let callback: CGEventTapCallBack = { _, _, event, _ in
    return Unmanaged.passRetained(event)
}

if let tap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: mask,
    callback: callback,
    userInfo: nil
) {
    print(" ✅ EventTap 创建成功")
    _ = tap  // CFMachPort auto-released by ARC
} else {
    print(" ❌ EventTap 创建失败")
    print("\n即使已授权,仍无法创建 EventTap。尝试:")
    print("  1. 在辅助功能列表中删除 keyboarddrop,重新添加")
    print("  2. 重启终端后重试")
    exit(1)
}

// Test 3: Check config loading
print("[3/3] 检查配置文件...")

let home = NSHomeDirectory()
let configPath = "\(home)/.keyboarddrop/config.json"

if FileManager.default.fileExists(atPath: configPath) {
    print(" ✅ 配置文件存在: \(configPath)")
    if let data = FileManager.default.contents(atPath: configPath),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let mappings = json["mappings"] as? [String: String] {
        print("    映射规则:")
        for (k, v) in mappings.sorted(by: { $0.key < $1.key }) {
            print("      \(k) → \(v)")
        }
    }
} else {
    print(" ⚠️  配置文件不存在(首次运行时会自动创建)")
}

print("\n✅ 所有接入性测试通过!keyboarddrop 可以正常启动。")
