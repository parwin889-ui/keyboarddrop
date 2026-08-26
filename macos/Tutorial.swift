import Foundation

func tutorialHTML() -> String {
    let zh = L10n.isChinese
    let title = zh ? "使用教程" : "Tutorial"
    let intro = zh ? "<strong>KeyboardDrop</strong> 是一个 macOS/Windows 键盘自定义工具，可以把任意按键重映射为其他按键，或绑定到自定义操作（启动应用、执行命令、截图、控制音量等）。" : "<strong>KeyboardDrop</strong> is a macOS/Windows keyboard customization tool. Remap any key to another key, or bind it to custom actions (launch apps, run commands, take screenshots, control volume, etc.)."

    let s1Title = zh ? "安装与授权" : "Installation & Permissions"
    let macSteps = zh ? """
    <p>1. 打开 <code>KeyboardDrop-1.3.0.dmg</code>，将 KeyboardDrop 拖入 Applications 文件夹</p>
    <p>2. 首次运行时，系统会提示需要辅助功能权限</p>
    <p>3. 前往 <code>系统设置 - 隐私与安全性 - 辅助功能</code>，启用 KeyboardDrop</p>
    <p>4. 也可以通过菜单栏点击「打开辅助功能设置」快捷跳转</p>
    """ : """
    <p>1. Open <code>KeyboardDrop-1.3.0.dmg</code>, drag KeyboardDrop to Applications</p>
    <p>2. On first launch, the system will prompt for Accessibility permission</p>
    <p>3. Go to <code>System Settings - Privacy & Security - Accessibility</code>, enable KeyboardDrop</p>
    <p>4. Or click "Open Accessibility Settings" from the menu bar</p>
    """
    let winSteps = zh ? """
    <p>1. 将 <code>KeyboardDrop-Windows</code> 文件夹复制到 Windows 电脑</p>
    <p>2. 安装 .NET 8 SDK</p>
    <p>3. 双击 <code>build.bat</code> 编译</p>
    <p>4. 运行生成的 <code>KeyboardDrop.exe</code></p>
    """ : """
    <p>1. Copy the <code>KeyboardDrop-Windows</code> folder to a Windows PC</p>
    <p>2. Install .NET 8 SDK</p>
    <p>3. Run <code>build.bat</code> to build</p>
    <p>4. Run the generated <code>KeyboardDrop.exe</code></p>
    """

    let s2Title = zh ? "配置格式" : "Configuration Format"
    let configPath = zh ? "配置文件位置：macOS 为 <code>~/.keyboarddrop/config.json</code>，Windows 为 <code>%APPDATA%\\KeyboardDrop\\config.json</code>" : "Config file: macOS <code>~/.keyboarddrop/config.json</code>, Windows <code>%APPDATA%\\KeyboardDrop\\config.json</code>"
    let configTip = zh ? "<strong>两种写法：</strong>字符串值 = 按键重映射；对象值 = 自定义操作（type + target）" : "<strong>Two formats:</strong> String value = key remap; Object value = custom action (type + target)"
    let guiNote = zh ? "也可以通过菜单栏 -「设置...」打开图形界面进行可视化编辑，保存后立即生效。" : "You can also use the menu bar - \"Settings...\" to open a GUI editor. Changes apply on save."

    let s3Title = zh ? "操作类型一览" : "Action Types Reference"
    let colType = zh ? "类型" : "Type"
    let colExample = zh ? "配置示例" : "Config Example"
    let colEffect = zh ? "效果" : "Effect"

    let s4Title = zh ? "按键名参考" : "Key Name Reference"
    let s5Title = zh ? "常用配置示例" : "Common Examples"
    let s6Title = zh ? "常见问题" : "FAQ"

    let noteText = zh ? "<strong>注意：</strong>自定义操作按键的 keyDown 和 keyUp 事件会被完全拦截（不会传递给系统），只有重映射类型的按键会修改后传递。请避免将正在使用的快捷键映射为操作。" : "<strong>Note:</strong> Custom action keys have both keyDown and keyUp events fully suppressed. Only remap-type keys are modified and passed through. Avoid mapping shortcuts you actively use."

    let configExample = """
    {
      "mappings": {
        "caps_lock": "escape",
        "right_command": "left_control",
        "f5": { "type": "command", "target": "open -a 'Activity Monitor'" },
        "f6": { "type": "screenshot", "target": "region" },
        "f7": { "type": "volume", "target": "mute" },
        "f10": { "type": "url", "target": "https://github.com" }
      }
    }
    """

    let gameExample = """
    {
      "mappings": {
        "caps_lock": "left_control",
        "right_command": "left_option",
        "f1": { "type": "command", "target": "open -a 'Discord'" },
        "f2": { "type": "command", "target": "open -a 'Steam'" }
      }
    }
    """

    let devExample = """
    {
      "mappings": {
        "caps_lock": "escape",
        "f1": { "type": "ssh", "target": "deploy@production-server.com" },
        "f2": { "type": "command", "target": "cd ~/projects && code ." },
        "f3": { "type": "script", "target": "~/scripts/deploy.sh" },
        "f4": { "type": "url", "target": "https://localhost:3000" }
      }
    }
    """

    let dailyExample = """
    {
      "mappings": {
        "f5": { "type": "screenshot", "target": "region" },
        "f6": { "type": "screenshot", "target": "full" },
        "f7": { "type": "volume", "target": "mute" },
        "f8": { "type": "media", "target": "play" },
        "f9": { "type": "system", "target": "lock" },
        "f10": { "type": "url", "target": "https://www.youtube.com" },
        "f11": { "type": "text", "target": "my-email@gmail.com" }
      }
    }
    """

    // Build action type rows
    let actions: [(String, String)] = [
        ("remap", zh ? "按键重映射" : "Key remapping"),
        ("app", zh ? "启动应用程序" : "Launch application"),
        ("command", zh ? "执行 Shell 命令" : "Run shell command"),
        ("ssh", zh ? "在终端中打开 SSH" : "Open SSH in Terminal"),
        ("file", zh ? "用默认应用打开文件" : "Open file with default app"),
        ("script", zh ? "执行脚本文件" : "Run script file"),
        ("screenshot", zh ? "截图（full/region/window/clipboard）" : "Screenshot (full/region/window/clipboard)"),
        ("url", zh ? "在浏览器中打开网址" : "Open URL in browser"),
        ("volume", zh ? "音量控制（up/down/mute/unmute/0-100）" : "Volume (up/down/mute/unmute/0-100)"),
        ("media", zh ? "媒体控制（play/next/prev）" : "Media (play/next/prev)"),
        ("text", zh ? "自动输入文本（宏）" : "Auto-type text (macro)"),
        ("system", zh ? "系统操作（sleep/lock/restart/shutdown/logout）" : "System (sleep/lock/restart/shutdown/logout)"),
    ]

    var actionRows = ""
    for a in actions {
        let example: String
        switch a.0 {
        case "remap": example = "<code>\"caps_lock\": \"escape\"</code>"
        case "app": example = "<code>{\"type\":\"app\",\"target\":\"/Applications/Safari.app\"}</code>"
        case "command": example = "<code>{\"type\":\"command\",\"target\":\"open -a Terminal\"}</code>"
        case "ssh": example = "<code>{\"type\":\"ssh\",\"target\":\"user@192.168.1.1\"}</code>"
        case "file": example = "<code>{\"type\":\"file\",\"target\":\"/path/to/file\"}</code>"
        case "script": example = "<code>{\"type\":\"script\",\"target\":\"/path/to/deploy.sh\"}</code>"
        case "screenshot": example = "<code>{\"type\":\"screenshot\",\"target\":\"region\"}</code>"
        case "url": example = "<code>{\"type\":\"url\",\"target\":\"https://github.com\"}</code>"
        case "volume": example = "<code>{\"type\":\"volume\",\"target\":\"mute\"}</code>"
        case "media": example = "<code>{\"type\":\"media\",\"target\":\"play\"}</code>"
        case "text": example = "<code>{\"type\":\"text\",\"target\":\"Hello World\"}</code>"
        case "system": example = "<code>{\"type\":\"system\",\"target\":\"lock\"}</code>"
        default: example = ""
        }
        actionRows += "<tr><td><strong>\(a.0)</strong></td><td>\(example)</td><td>\(a.1)</td></tr>"
    }

    // Key name reference rows
    let keyCats: [(String, String)] = [
        (zh ? "字母" : "Letters", "a b c d ... z"),
        (zh ? "数字" : "Numbers", "0 1 2 ... 9"),
        (zh ? "符号" : "Symbols", "minus equal left_bracket right_bracket backslash semicolon quote grave comma period slash"),
        (zh ? "空白键" : "Whitespace", "tab space return escape delete forward_delete"),
        (zh ? "修饰键" : "Modifiers", "caps_lock left_shift right_shift left_control right_control left_option right_option left_command right_command"),
        (zh ? "功能键" : "Function", "f1 f2 ... f12"),
        (zh ? "方向键" : "Arrows", "up_arrow down_arrow left_arrow right_arrow"),
        (zh ? "导航键" : "Navigation", "home end page_up page_down"),
    ]
    var keyRows = ""
    for kc in keyCats {
        keyRows += "<tr><td>\(kc.0)</td><td><code>\(kc.1)</code></td></tr>"
    }

    // FAQ entries
    let faqs: [(String, String)] = [
        (zh ? "按下映射键没反应？" : "Pressed the mapped key but nothing happens?",
         zh ? "检查辅助功能权限是否已授予（菜单栏 - 打开辅助功能设置）。如果权限已开但仍无效，尝试点击菜单栏的「重载配置」。" : "Check if Accessibility permission is granted. If granted but still not working, try \"Reload Config\" from the menu bar."),
        (zh ? "caps_lock 映射不稳定？" : "caps_lock remapping is unreliable?",
         zh ? "macOS 对 caps_lock 有特殊底层处理，CGEventTap 无法完美拦截。如需完美 caps_lock 映射，建议使用 Karabiner-Elements。" : "macOS has special low-level handling for caps_lock that CGEventTap can't perfectly intercept. Consider Karabiner-Elements."),
        (zh ? "修改配置后如何生效？" : "How to apply config changes?",
         zh ? "两种方式：1) 菜单栏 - 重载配置；2) 菜单栏 - 设置... - 保存并应用。两种方式都会立即生效，无需重启。" : "Two ways: 1) Menu bar - Reload Config; 2) Menu bar - Settings... - Save & Apply. Both apply immediately without restart."),
        (zh ? "音量/媒体控制不工作？" : "Volume/media control doesn't work?",
         zh ? "这些功能依赖 AppleScript 自动化权限。请确保在「系统设置 - 隐私与安全性 - 自动化」中授予 KeyboardDrop 相关权限。" : "These features rely on AppleScript automation permissions. Ensure KeyboardDrop is granted permission in System Settings - Privacy & Security - Automation."),
        (zh ? "如何切换中英文？" : "How to switch language?",
         zh ? "菜单栏点击键盘图标 - 选择「Switch to English」或「切换为中文」即可切换界面语言。" : "Click the keyboard icon in the menu bar - select \"Switch to English\" or toggle language."),
    ]
    var faqHTML = ""
    for (i, faq) in faqs.enumerated() {
        faqHTML += "<div class='card'><h3>Q\(i+1): \(faq.0)</h3><p>A: \(faq.1)</p></div>"
    }

    let gameTitle = zh ? "游戏键位" : "Gaming Layout"
    let devTitle = zh ? "开发者效率" : "Developer Productivity"
    let dailyTitle = zh ? "日常快捷" : "Everyday Shortcuts"

    return """
    <!DOCTYPE html>
    <html lang="\(zh ? "zh" : "en")">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>KeyboardDrop \(title)</title>
    <style>
        :root { --bg: #1a1a2e; --card: #16213e; --accent: #0f3460; --text: #e8e8e8; --code: #e94560; --border: #2a2a4a; }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, "SF Pro Text", "Helvetica Neue", sans-serif; background: var(--bg); color: var(--text); line-height: 1.7; padding: 20px; max-width: 860px; margin: 0 auto; }
        h1 { color: #e94560; font-size: 2em; margin: 20px 0; border-bottom: 2px solid var(--border); padding-bottom: 10px; }
        h2 { color: #0ff; font-size: 1.4em; margin: 24px 0 12px; padding-left: 12px; border-left: 4px solid #e94560; }
        h3 { color: #8be9fd; margin: 16px 0 8px; }
        .card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin: 16px 0; }
        .card h3 { margin-top: 0; }
        code { background: var(--accent); color: var(--code); padding: 2px 6px; border-radius: 4px; font-family: "SF Mono", monospace; font-size: 0.9em; }
        pre { background: #0d1b2a; border: 1px solid var(--border); border-radius: 8px; padding: 16px; overflow-x: auto; margin: 12px 0; }
        pre code { background: none; color: #a5d7e8; padding: 0; }
        table { width: 100%; border-collapse: collapse; margin: 12px 0; }
        th, td { padding: 10px 14px; border: 1px solid var(--border); text-align: left; }
        th { background: var(--accent); color: #0ff; }
        tr:nth-child(even) { background: var(--card); }
        .tip { background: rgba(15,52,96,0.5); border-left: 4px solid #0ff; padding: 12px 16px; border-radius: 0 8px 8px 0; margin: 12px 0; }
        .warn { background: rgba(233,69,96,0.15); border-left: 4px solid #e94560; padding: 12px 16px; border-radius: 0 8px 8px 0; margin: 12px 0; }
        .footer { text-align: center; margin: 40px 0 20px; color: #555; font-size: 0.85em; }
    </style>
    </head>
    <body>

    <h1>KeyboardDrop \(title)</h1>

    <div class="tip">\(intro)</div>

    <h2>1. \(s1Title)</h2>
    <div class="card"><h3>macOS</h3>\(macSteps)</div>
    <div class="card"><h3>Windows</h3>\(winSteps)</div>

    <h2>2. \(s2Title)</h2>
    <p>\(configPath)</p>
    <pre><code>\(configExample)</code></pre>
    <div class="tip">\(configTip)</div>
    <p>\(guiNote)</p>

    <h2>3. \(s3Title)</h2>
    <table>
    <tr><th>\(colType)</th><th>\(colExample)</th><th>\(colEffect)</th></tr>
    \(actionRows)
    </table>

    <h2>4. \(s4Title)</h2>
    <div class="card">
    <table>
    <tr><th>\(zh ? "分类" : "Category")</th><th>\(zh ? "按键名" : "Key Names")</th></tr>
    \(keyRows)
    </table>
    </div>

    <h2>5. \(s5Title)</h2>
    <h3>\(gameTitle)</h3>
    <pre><code>\(gameExample)</code></pre>
    <h3>\(devTitle)</h3>
    <pre><code>\(devExample)</code></pre>
    <h3>\(dailyTitle)</h3>
    <pre><code>\(dailyExample)</code></pre>

    <h2>6. \(s6Title)</h2>
    \(faqHTML)

    <div class="warn">\(noteText)</div>

    <div class="footer">KeyboardDrop v1.3.0 - macOS 12+ / Windows 10+ - \(zh ? "基于 CGEventTap / WH_KEYBOARD_LL" : "Powered by CGEventTap / WH_KEYBOARD_LL")</div>

    </body>
    </html>
    """
}
