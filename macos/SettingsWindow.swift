import Cocoa
import CoreGraphics

// MARK: - Mapping row model

struct MappingRow {
    var sourceKey: String
    var actionType: String
    var target: String

    func toDescription() -> String {
        "\(sourceKey) -> [\(actionType)] \(target)"
    }
}

// MARK: - Settings Window

class SettingsWindow: NSWindow, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, NSComboBoxDelegate {

    private var tableView: NSTableView!
    private var rows: [MappingRow] = []
    private var configPath: String!
    private var onSaved: (() -> Void)?

    private let keyNames = KeyMap.nameToCode.keys.sorted()
    private let actionTypes = ["remap", "app", "command", "ssh", "file", "script", "screenshot", "url", "volume", "media", "text", "system"]

    static func show(configPath: String, onSaved: @escaping () -> Void) {
        let window = SettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.t("KeyboardDrop 设置", "KeyboardDrop Settings")
        window.configPath = configPath
        window.onSaved = onSaved
        window.center()
        window.setupUI()
        window.loadConfig()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupUI() {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 420))

        // Table with scroll view
        let scrollView = NSScrollView(frame: NSRect(x: 12, y: 60, width: 576, height: 310))
        tableView = NSTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = true
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.usesAlternatingRowBackgroundColors = true

        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("source"))
        col1.title = L10n.t("按键", "Key")
        col1.width = 120
        tableView.addTableColumn(col1)

        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("type"))
        col2.title = L10n.t("操作", "Action")
        col2.width = 120
        tableView.addTableColumn(col2)

        let col3 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("target"))
        col3.title = L10n.t("目标", "Target")
        col3.width = 300
        tableView.addTableColumn(col3)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        containerView.addSubview(scrollView)

        // Add button
        let addButton = NSButton(title: L10n.t("+ 添加", "+ Add"), target: self, action: #selector(addRow))
        addButton.frame = NSRect(x: 12, y: 12, width: 80, height: 30)
        addButton.bezelStyle = .rounded
        containerView.addSubview(addButton)

        // Remove button
        let removeButton = NSButton(title: L10n.t("- 删除", "- Remove"), target: self, action: #selector(removeRow))
        removeButton.frame = NSRect(x: 100, y: 12, width: 100, height: 30)
        removeButton.bezelStyle = .rounded
        containerView.addSubview(removeButton)

        // Save button
        let saveButton = NSButton(title: L10n.t("保存并应用", "Save & Apply"), target: self, action: #selector(save))
        saveButton.frame = NSRect(x: 420, y: 12, width: 160, height: 30)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        containerView.addSubview(saveButton)

        // Hint label
        let hint = NSTextField(labelWithString: L10n.t("双击单元格编辑，保存后立即生效。", "Edit cells by double-clicking. Changes apply on Save."))
        hint.frame = NSRect(x: 12, y: 42, width: 576, height: 14)
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        containerView.addSubview(hint)

        self.contentView = containerView
    }

    // MARK: - Config loading

    private func loadConfig() {
        guard let data = FileManager.default.contents(atPath: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        let mappings = json["mappings"] as? [String: Any] ?? json
        rows = mappings.map { (key, value) in
            if let str = value as? String {
                return MappingRow(sourceKey: key, actionType: "remap", target: str)
            }
            if let dict = value as? [String: Any] {
                return MappingRow(
                    sourceKey: key,
                    actionType: dict["type"] as? String ?? "",
                    target: dict["target"] as? String ?? ""
                )
            }
            return MappingRow(sourceKey: key, actionType: "", target: "")
        }.sorted { $0.sourceKey < $1.sourceKey }

        tableView.reloadData()
    }

    // MARK: - Table view data source

    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count else { return nil }
        let r = rows[row]
        let id = tableColumn?.identifier.rawValue ?? ""

        if id == "source" {
            let combo = NSComboBox(frame: NSRect(x: 0, y: 0, width: 110, height: 26))
            combo.isEditable = true
            combo.addItems(withObjectValues: keyNames)
            combo.stringValue = r.sourceKey
            combo.tag = row
            combo.delegate = self
            combo.identifier = NSUserInterfaceItemIdentifier("source")
            return combo
        }

        if id == "type" {
            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 110, height: 26), pullsDown: false)
            for a in actionTypes {
                popup.addItem(withTitle: a)
            }
            popup.selectItem(withTitle: r.actionType)
            popup.tag = row
            popup.target = self
            popup.action = #selector(typeChanged(_:))
            popup.identifier = NSUserInterfaceItemIdentifier("type")
            return popup
        }

        if id == "target" {
            let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 26))
            field.stringValue = r.target
            field.tag = row
            field.delegate = self
            field.identifier = NSUserInterfaceItemIdentifier("target")
            return field
        }

        return nil
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 28
    }

    // MARK: - Actions

    @objc private func addRow() {
        rows.append(MappingRow(sourceKey: "", actionType: "remap", target: ""))
        tableView.reloadData()
        let idx = rows.count - 1
        tableView.editColumn(0, row: idx, with: nil, select: true)
    }

    @objc private func removeRow() {
        let selected = tableView.selectedRowIndexes
        if selected.isEmpty { return }
        var newRows: [MappingRow] = []
        for i in 0..<rows.count {
            if !selected.contains(i) {
                newRows.append(rows[i])
            }
        }
        rows = newRows
        tableView.reloadData()
    }

    @objc private func typeChanged(_ sender: NSPopUpButton) {
        let row = sender.tag
        if row < rows.count {
            rows[row].actionType = sender.titleOfSelectedItem ?? ""
        }
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField,
              let id = field.identifier?.rawValue,
              field.tag < rows.count else { return }

        if id == "source" {
            rows[field.tag].sourceKey = field.stringValue
        }
        if id == "target" {
            rows[field.tag].target = field.stringValue
        }
    }

    func comboBoxSelectionDidChange(_ obj: Notification) {
        guard let combo = obj.object as? NSComboBox,
              let id = combo.identifier?.rawValue,
              combo.tag < rows.count else { return }

        if id == "source" {
            rows[combo.tag].sourceKey = combo.stringValue
        }
    }

    @objc private func save() {
        var mappings: [String: Any] = [:]
        for r in rows {
            let key = r.sourceKey.trimmingCharacters(in: .whitespaces)
            if key.isEmpty { continue }
            if r.actionType == "remap" {
                mappings[key] = r.target
            } else {
                mappings[key] = ["type": r.actionType, "target": r.target]
            }
        }

        let config: [String: Any] = ["mappings": mappings]
        let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
        try? data?.write(to: URL(fileURLWithPath: configPath))

        print("keyboarddrop: saved \(mappings.count) mapping(s) to \(configPath ?? "")")
        onSaved?()
        close()
    }
}
