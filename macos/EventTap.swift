import Cocoa
import CoreGraphics

// MARK: - Modifier flag helper

func modifierFlag(for keyCode: CGKeyCode) -> CGEventFlags? {
    switch keyCode {
    case 0x38, 0x3C: return .maskShift
    case 0x3B, 0x3E: return .maskControl
    case 0x3A, 0x3D: return .maskAlternate
    case 0x37, 0x36: return .maskCommand
    case 0x39:        return .maskAlphaShift
    case 0x3F:        return .maskSecondaryFn
    default:          return nil
    }
}

// MARK: - Event tap callback (must be top-level @convention(c))

private func keyboardEventCallback(
    _ proxy: CGEventTapProxy,
    _ type: CGEventType,
    _ event: CGEvent,
    _ refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }

    let tap = Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue()

    // Re-enable if the system disabled the tap
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let port = tap.port {
            CGEvent.tapEnable(tap: port, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    guard type == .keyDown || type == .keyUp || type == .flagsChanged else {
        return Unmanaged.passRetained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    guard let action = tap.actions[CGKeyCode(keyCode)] else {
        return Unmanaged.passRetained(event)
    }

    // Handle simple key remap
    if case .remap(let mappedKeyCode) = action {
        if type == .flagsChanged {
            // Modifier remap: swap keycode + flags
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mappedKeyCode))

            var flagsRaw = event.flags.rawValue
            let sourceFlag = modifierFlag(for: CGKeyCode(keyCode))
            let targetFlag = modifierFlag(for: mappedKeyCode)

            if let s = sourceFlag, let t = targetFlag {
                if (flagsRaw & s.rawValue) != 0 {
                    flagsRaw &= ~s.rawValue
                    flagsRaw |= t.rawValue
                } else {
                    flagsRaw &= ~t.rawValue
                }
            }
            event.flags = CGEventFlags(rawValue: flagsRaw)
        } else {
            // Regular key remap
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mappedKeyCode))

            var flagsRaw = event.flags.rawValue
            if let s = modifierFlag(for: CGKeyCode(keyCode)) {
                flagsRaw &= ~s.rawValue
            }
            if let t = modifierFlag(for: mappedKeyCode) {
                flagsRaw |= t.rawValue
            }
            event.flags = CGEventFlags(rawValue: flagsRaw)
        }

        return Unmanaged.passRetained(event)
    }

    // Handle custom action: suppress key event, execute on keyDown only
    if type == .keyDown {
        DispatchQueue.global(qos: .userInitiated).async {
            action.execute()
        }
    }

    // Suppress both keyDown and keyUp for action keys
    return nil
}

// MARK: - EventTap

final class EventTap {
    private(set) var port: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var actions: [CGKeyCode: KeyAction] = [:]
    private(set) var isActive = false

    func updateActions(_ newActions: [CGKeyCode: KeyAction]) {
        actions = newActions
    }

    func start() {
        guard port == nil else { return }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
                   | CGEventMask(1 << CGEventType.keyUp.rawValue)
                   | CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: keyboardEventCallback,
            userInfo: refcon
        ) else {
            fputs("Failed to create event tap.\nGrant Accessibility permission:\n  System Settings → Privacy & Security → Accessibility\n", stderr)
            isActive = false
            return
        }

        port = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isActive = true
    }

    func stop() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        if let tap = port {
            CGEvent.tapEnable(tap: tap, enable: false)
            port = nil
        }
        isActive = false
    }
}
