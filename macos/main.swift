import Cocoa

setvbuf(stdout, nil, _IOLBF, 0)
setvbuf(stderr, nil, _IOLBF, 0)

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var eventTap: EventTap!
    private var configPath: String = ""
    private var config: Config?

    func applicationDidFinishLaunching(_ notification: Notification) {
        eventTap = EventTap()
        configPath = resolveConfigPath()

        loadConfig()
        eventTap.start()

        statusItem = NSStatusBar.system.statusItem(withLength: 30)
        statusItem.button?.image = makeIcon(size: 28)
        statusItem.button?.imagePosition = .imageOnly
        rebuildMenu()
    }

    // MARK: - Icon

    private func makeIcon(size: CGFloat) -> NSImage {
        let icon = NSImage(size: NSSize(width: size, height: size))
        icon.lockFocus()

        // Keyboard body — fill with medium gray
        let bodyRect = NSRect(x: size * 0.05, y: size * 0.1, width: size * 0.9, height: size * 0.7)
        let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: size * 0.12, yRadius: size * 0.12)
        NSColor.darkGray.setFill()
        bodyPath.fill()

        // Keys — 2 rows x 5 cols, cut out as lighter rectangles
        let cols = 5
        let rows = 2
        let margin = size * 0.14
        let gap = size * 0.04
        let availW = size - margin * 2
        let keyW = (availW - gap * CGFloat(cols - 1)) / CGFloat(cols)
        let keyH = keyW * 0.9
        let startX = margin
        let startY = size * 0.22
        NSColor.lightGray.setFill()
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (keyW + gap)
                let y = startY + CGFloat(row) * (keyH + gap)
                NSBezierPath(roundedRect: NSRect(x: x, y: y, width: keyW, height: keyH), xRadius: 1.5, yRadius: 1.5).fill()
            }
        }

        // Spacebar
        let spaceW = keyW * 3 + gap * 2
        let spaceX = startX + (availW - spaceW) / 2
        let spaceY = startY - keyH - gap
        NSBezierPath(roundedRect: NSRect(x: spaceX, y: spaceY, width: spaceW, height: keyH), xRadius: 1.5, yRadius: 1.5).fill()

        icon.unlockFocus()
        icon.isTemplate = false
        return icon
    }

    // MARK: - Config

    private func resolveConfigPath() -> String {
        if CommandLine.arguments.count > 1 {
            let arg = CommandLine.arguments[1]
            if arg == "--config" && CommandLine.arguments.count > 2 {
                return CommandLine.arguments[2]
            }
            if !arg.hasPrefix("-") {
                return arg
            }
        }

        let home = NSHomeDirectory()
        let homeConfig = "\(home)/.keyboarddrop/config.json"
        if FileManager.default.fileExists(atPath: homeConfig) {
            return homeConfig
        }

        let localConfig = "config.json"
        if FileManager.default.fileExists(atPath: localConfig) {
            return localConfig
        }

        return homeConfig
    }

    @discardableResult
    private func loadConfig() -> Bool {
        config = Config.load(from: configPath)

        if let config = config {
            let keyActions = config.toKeyActions()
            eventTap.updateActions(keyActions)
            print("keyboarddrop: loaded \(keyActions.count) mapping(s) from \(configPath)")
            return true
        }

        // Create a default config if none exists
        let dir = (configPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        if !FileManager.default.fileExists(atPath: configPath) {
            let defaultConfig = """
            {
              "mappings": {
                "caps_lock": "escape",
                "right_command": "left_control",
                "f5": { "type": "command", "target": "open -a 'Activity Monitor'" },
                "f6": { "type": "screenshot", "target": "region" },
                "f7": { "type": "volume", "target": "mute" },
                "f8": { "type": "media", "target": "play" },
                "f9": { "type": "system", "target": "lock" },
                "f10": { "type": "url", "target": "https://github.com" }
              }
            }
            """
            try? defaultConfig.write(toFile: configPath, atomically: true, encoding: .utf8)
            print("keyboarddrop: created default config at \(configPath)")
            config = Config.load(from: configPath)
            if let config = config {
                eventTap.updateActions(config.toKeyActions())
            }
        }

        return false
    }

    // MARK: - Menu

    private func rebuildMenu() {
        let menu = NSMenu()

        let statusActive = L10n.t("● 运行中", "● Active")
        let statusPaused = L10n.t("○ 已暂停", "○ Paused")
        let status = eventTap.isActive ? statusActive : statusPaused
        let statusMenuItem = menu.addItem(withTitle: status, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false

        menu.addItem(.separator())

        let toggleTitle = eventTap.isActive ? L10n.t("暂停", "Pause") : L10n.t("恢复", "Resume")
        menu.addItem(withTitle: toggleTitle, action: #selector(toggle), keyEquivalent: "")

        menu.addItem(withTitle: L10n.t("重载配置", "Reload Config"), action: #selector(reloadConfig), keyEquivalent: "r")

        menu.addItem(withTitle: L10n.t("设置...", "Settings..."), action: #selector(openSettings), keyEquivalent: ",")

        menu.addItem(withTitle: L10n.t("使用教程", "Tutorial"), action: #selector(openTutorial), keyEquivalent: "?")

        // Language toggle
        let langTitle = L10n.isChinese ? "Switch to English" : "切换为中文"
        menu.addItem(withTitle: langTitle, action: #selector(toggleLanguage), keyEquivalent: "")

        menu.addItem(.separator())

        if let config = config, !config.rawMappings.isEmpty {
            let mappingsItem = menu.addItem(withTitle: L10n.t("当前映射", "Mappings"), action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            for desc in config.describe() {
                let item = submenu.addItem(withTitle: desc, action: nil, keyEquivalent: "")
                item.isEnabled = false
            }
            mappingsItem.submenu = submenu
        } else {
            let item = menu.addItem(withTitle: L10n.t("未配置映射", "No mappings configured"), action: nil, keyEquivalent: "")
            item.isEnabled = false
        }

        menu.addItem(.separator())

        let configLabel = menu.addItem(
            withTitle: L10n.t("配置文件", "Config") + ": \(configPath)",
            action: #selector(revealConfig),
            keyEquivalent: ""
        )
        configLabel.toolTip = configPath

        menu.addItem(
            withTitle: L10n.t("打开辅助功能设置", "Open Accessibility Settings"),
            action: #selector(openAccessibility),
            keyEquivalent: ""
        )

        menu.addItem(.separator())
        menu.addItem(withTitle: L10n.t("退出 KeyboardDrop", "Quit KeyboardDrop"), action: #selector(quit), keyEquivalent: "q")

        for item in menu.items {
            item.target = self
            if let sub = item.submenu {
                for subItem in sub.items {
                    subItem.target = self
                }
            }
        }

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func toggle() {
        if eventTap.isActive {
            eventTap.stop()
        } else {
            eventTap.start()
        }
        rebuildMenu()
    }

    @objc private func reloadConfig() {
        loadConfig()
        rebuildMenu()
    }

    @objc private func openSettings() {
        SettingsWindow.show(configPath: configPath) { [weak self] in
            self?.loadConfig()
            self?.rebuildMenu()
        }
    }

    @objc private func toggleLanguage() {
        L10n.toggle()
        rebuildMenu()
    }

    @objc private func openTutorial() {
        let html = tutorialHTML()
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("keyboarddrop_tutorial.html")
        try? html.write(to: tmpURL, atomically: true, encoding: .utf8)
        NSWorkspace.shared.open(tmpURL)
    }

    @objc private func revealConfig() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: configPath)])
    }

    @objc private func openAccessibility() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        eventTap.stop()
        NSApp.terminate(nil)
    }
}

// MARK: - Menu delegate (refresh on open)

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }
}

// MARK: - Entry point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // no Dock icon — menu bar only
app.activate(ignoringOtherApps: true)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
