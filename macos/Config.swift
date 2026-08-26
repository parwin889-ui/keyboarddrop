import Foundation
import CoreGraphics

struct Config {
    var rawMappings: [String: Any]

    static func load(from path: String) -> Config? {
        guard let data = FileManager.default.contents(atPath: path) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let mappingsDict = json["mappings"] as? [String: Any] {
            return Config(rawMappings: mappingsDict)
        }

        // Flat format: filter out non-mapping keys
        var flat: [String: Any] = [:]
        for (key, value) in json {
            if value is String || value is [String: Any] {
                flat[key] = value
            }
        }
        if !flat.isEmpty {
            return Config(rawMappings: flat)
        }

        return nil
    }

    func toKeyActions() -> [CGKeyCode: KeyAction] {
        var result: [CGKeyCode: KeyAction] = [:]
        for (from, raw) in rawMappings {
            guard let fromCode = KeyMap.code(for: from) else {
                print("  [warning] unknown source key: \(from)")
                continue
            }
            if let action = KeyAction.fromConfig(raw) {
                result[fromCode] = action
            }
        }
        return result
    }

    func describe() -> [String] {
        rawMappings
            .sorted { $0.key < $1.key }
            .map { (from, raw) -> String in
                if let action = KeyAction.fromConfig(raw) {
                    return "\(from) \(action.description)"
                }
                return "\(from) → (invalid)"
            }
    }
}
