#!/usr/bin/env python3
"""KeyboardDrop for Linux - Global keyboard remapping using evdev + uinput.

Usage:
    sudo python3 main.py

Requirements:
    - Python 3.10+
    - evdev library (pip install evdev)
    - Root access (required to read /dev/input/* and write /dev/uinput)
"""
import argparse
import os
import signal
import sys
import time
from pathlib import Path

import evdev
from evdev import UInput, ecodes, AbsInfo

from config import load_config, get_config_path
from keymap import code_for, name_for


class KeyboardDrop:
    """Main keyboard remapping application."""

    def __init__(self):
        self.running = False
        self.device = None
        self.ui = None
        self.mappings = {}  # key_code -> target_key_code
        self._setup_signal_handlers()

    def _setup_signal_handlers(self):
        """Handle SIGINT and SIGTERM for clean shutdown."""
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def _signal_handler(self, signum, frame):
        print(f"\nReceived signal {signum}, shutting down...")
        self.running = False

    def load_mappings(self, config: dict) -> int:
        """Load key mappings from config.

        Returns the number of valid mappings loaded.
        """
        self.mappings = {}
        mappings = config.get("mappings", {})

        for src_name, dst_name in mappings.items():
            src_code = code_for(src_name)
            dst_code = code_for(dst_name)

            if src_code is None:
                print(f"Warning: Unknown source key '{src_name}'", file=sys.stderr)
                continue
            if dst_code is None:
                print(f"Warning: Unknown target key '{dst_name}'", file=sys.stderr)
                continue

            self.mappings[src_code] = dst_code

        return len(self.mappings)

    def find_keyboard_device(self) -> evdev.InputDevice | None:
        """Find a keyboard input device.

        Returns the first device with keys that looks like a keyboard.
        """
        devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
        keyboards = []

        for dev in devices:
            caps = dev.capabilities()
            # A keyboard should have EV_KEY and a reasonable number of keys
            if ecodes.EV_KEY in caps and len(caps[ecodes.EV_KEY]) > 20:
                # Skip devices that are clearly not keyboards (mice, touchpads, etc.)
                keys = caps[ecodes.EV_KEY]
                if ecodes.KEY_A in keys and ecodes.KEY_ENTER in keys:
                    keyboards.append(dev)

        if not keyboards:
            return None

        # Prefer devices with "keyboard" in name
        for dev in keyboards:
            if "keyboard" in dev.name.lower():
                return dev

        return keyboards[0]

    def create_uinput_device(self) -> UInput:
        """Create a virtual uinput keyboard device."""
        # Define a standard keyboard capability
        cap = {
            ecodes.EV_KEY: list(self._get_all_key_codes()),
            ecodes.EV_SYN: [ecodes.SYN_REPORT, ecodes.SYN_CONFIG],
        }
        return UInput(events=cap, name="KeyboardDrop Virtual Keyboard", version=0x1)

    def _get_all_key_codes(self) -> set:
        """Get all key codes that the virtual device should support."""
        codes = set()
        # Add all keys from our mapping
        from keymap import NAME_TO_CODE
        for code in NAME_TO_CODE.values():
            codes.add(code)
        # Also add common modifier keys
        codes.update([
            ecodes.KEY_LEFTSHIFT, ecodes.KEY_RIGHTSHIFT,
            ecodes.KEY_LEFTCTRL, ecodes.KEY_RIGHTCTRL,
            ecodes.KEY_LEFTALT, ecodes.KEY_RIGHTALT,
            ecodes.KEY_LEFTMETA, ecodes.KEY_RIGHTMETA,
            ecodes.KEY_CAPSLOCK, ecodes.KEY_NUMLOCK,
        ])
        return codes

    def start(self):
        """Start the keyboard remapper."""
        # Load config
        config = load_config()
        mapping_count = self.load_mappings(config)
        print(f"Loaded {mapping_count} key mappings from {get_config_path()}")

        if mapping_count == 0:
            print("Warning: No valid mappings configured. KeyboardDrop will pass through all keys.")

        # Find keyboard device
        self.device = self.find_keyboard_device()
        if self.device is None:
            print("Error: No keyboard device found. Make sure you have a keyboard connected.", file=sys.stderr)
            print("Tip: You may need to run this program as root (sudo).", file=sys.stderr)
            sys.exit(1)

        print(f"Using keyboard: {self.device.name} ({self.device.path})")

        # Create virtual uinput device
        self.ui = self.create_uinput_device()
        print(f"Virtual keyboard created: {self.ui.name}")

        # Grab the physical keyboard (exclusive access)
        try:
            self.device.grab()
            print("Keyboard grabbed successfully (exclusive mode)")
        except OSError as e:
            print(f"Warning: Could not grab keyboard: {e}", file=sys.stderr)
            print("Keys may be sent to both the original output and remapped output.", file=sys.stderr)

        # Main event loop
        self.running = True
        print("KeyboardDrop is running. Press Ctrl+C to stop.")

        try:
            self._event_loop()
        finally:
            self._cleanup()

    def _event_loop(self):
        """Main event processing loop."""
        for event in self.device.read_loop():
            if not self.running:
                break

            if event.type == ecodes.EV_KEY:
                # Remap key if it's in our mappings
                if event.code in self.mappings:
                    event.code = self.mappings[event.code]

                # Write the (possibly remapped) event to the virtual device
                self.ui.write(ecodes.EV_KEY, event.code, event.value)
                self.ui.syn()
            elif event.type == ecodes.EV_SYN:
                # Sync events pass through
                self.ui.write(ecodes.EV_SYN, event.code, event.value)
            else:
                # Other event types (MSC, etc.) pass through
                self.ui.write(event.type, event.code, event.value)
                self.ui.syn()

    def _cleanup(self):
        """Clean up resources."""
        print("Cleaning up...")
        if self.device:
            try:
                self.device.ungrab()
            except Exception:
                pass
            try:
                self.device.close()
            except Exception:
                pass
        if self.ui:
            try:
                self.ui.close()
            except Exception:
                pass
        print("KeyboardDrop stopped.")


def list_keyboards():
    """List all available keyboard-like input devices."""
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    if not devices:
        print("No input devices found.")
        print("Tip: You may need to run this program as root (sudo).")
        return

    print("Available input devices:")
    for dev in devices:
        caps = dev.capabilities()
        is_keyboard = (
            ecodes.EV_KEY in caps
            and len(caps[ecodes.EV_KEY]) > 20
            and ecodes.KEY_A in caps.get(ecodes.EV_KEY, [])
        )
        label = " [KEYBOARD]" if is_keyboard else ""
        print(f"  {dev.path}: {dev.name}{label}")


def main():
    parser = argparse.ArgumentParser(
        description="KeyboardDrop - Global keyboard remapping tool for Linux"
    )
    parser.add_argument(
        "--list-devices",
        action="store_true",
        help="List available input devices and exit",
    )
    args = parser.parse_args()

    if args.list_devices:
        list_keyboards()
        return

    # Check if running as root
    if os.geteuid() != 0:
        print("Warning: KeyboardDrop may need root access to read input devices.", file=sys.stderr)
        print("Tip: Run with 'sudo' if you encounter permission errors.\n", file=sys.stderr)

    app = KeyboardDrop()
    app.start()


if __name__ == "__main__":
    main()
