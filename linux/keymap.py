"""Key name to Linux input event code mapping."""
from evdev import ecodes

# Maps friendly key names to Linux KEY_* codes
# Names are kept consistent with the macOS and Windows versions
NAME_TO_CODE = {
    # Letters
    "a": ecodes.KEY_A,
    "b": ecodes.KEY_B,
    "c": ecodes.KEY_C,
    "d": ecodes.KEY_D,
    "e": ecodes.KEY_E,
    "f": ecodes.KEY_F,
    "g": ecodes.KEY_G,
    "h": ecodes.KEY_H,
    "i": ecodes.KEY_I,
    "j": ecodes.KEY_J,
    "k": ecodes.KEY_K,
    "l": ecodes.KEY_L,
    "m": ecodes.KEY_M,
    "n": ecodes.KEY_N,
    "o": ecodes.KEY_O,
    "p": ecodes.KEY_P,
    "q": ecodes.KEY_Q,
    "r": ecodes.KEY_R,
    "s": ecodes.KEY_S,
    "t": ecodes.KEY_T,
    "u": ecodes.KEY_U,
    "v": ecodes.KEY_V,
    "w": ecodes.KEY_W,
    "x": ecodes.KEY_X,
    "y": ecodes.KEY_Y,
    "z": ecodes.KEY_Z,
    # Numbers
    "0": ecodes.KEY_0,
    "1": ecodes.KEY_1,
    "2": ecodes.KEY_2,
    "3": ecodes.KEY_3,
    "4": ecodes.KEY_4,
    "5": ecodes.KEY_5,
    "6": ecodes.KEY_6,
    "7": ecodes.KEY_7,
    "8": ecodes.KEY_8,
    "9": ecodes.KEY_9,
    # Symbols
    "minus": ecodes.KEY_MINUS,
    "equal": ecodes.KEY_EQUAL,
    "left_bracket": ecodes.KEY_LEFTBRACE,
    "right_bracket": ecodes.KEY_RIGHTBRACE,
    "backslash": ecodes.KEY_BACKSLASH,
    "semicolon": ecodes.KEY_SEMICOLON,
    "quote": ecodes.KEY_APOSTROPHE,
    "grave": ecodes.KEY_GRAVE,
    "comma": ecodes.KEY_COMMA,
    "period": ecodes.KEY_DOT,
    "slash": ecodes.KEY_SLASH,
    # Whitespace & control
    "tab": ecodes.KEY_TAB,
    "space": ecodes.KEY_SPACE,
    "return": ecodes.KEY_ENTER,
    "escape": ecodes.KEY_ESC,
    "delete": ecodes.KEY_BACKSPACE,
    "forward_delete": ecodes.KEY_DELETE,
    # Modifiers
    "caps_lock": ecodes.KEY_CAPSLOCK,
    "left_shift": ecodes.KEY_LEFTSHIFT,
    "right_shift": ecodes.KEY_RIGHTSHIFT,
    "left_control": ecodes.KEY_LEFTCTRL,
    "right_control": ecodes.KEY_RIGHTCTRL,
    "left_option": ecodes.KEY_LEFTALT,
    "right_option": ecodes.KEY_RIGHTALT,
    "left_command": ecodes.KEY_LEFTMETA,
    "right_command": ecodes.KEY_RIGHTMETA,
    "left_win": ecodes.KEY_LEFTMETA,
    "right_win": ecodes.KEY_RIGHTMETA,
    "left_alt": ecodes.KEY_LEFTALT,
    "right_alt": ecodes.KEY_RIGHTALT,
    # Function keys
    "f1": ecodes.KEY_F1,
    "f2": ecodes.KEY_F2,
    "f3": ecodes.KEY_F3,
    "f4": ecodes.KEY_F4,
    "f5": ecodes.KEY_F5,
    "f6": ecodes.KEY_F6,
    "f7": ecodes.KEY_F7,
    "f8": ecodes.KEY_F8,
    "f9": ecodes.KEY_F9,
    "f10": ecodes.KEY_F10,
    "f11": ecodes.KEY_F11,
    "f12": ecodes.KEY_F12,
    # Arrow keys
    "up_arrow": ecodes.KEY_UP,
    "down_arrow": ecodes.KEY_DOWN,
    "left_arrow": ecodes.KEY_LEFT,
    "right_arrow": ecodes.KEY_RIGHT,
    # Navigation
    "home": ecodes.KEY_HOME,
    "end": ecodes.KEY_END,
    "page_up": ecodes.KEY_PAGEUP,
    "page_down": ecodes.KEY_PAGEDOWN,
}

# Reverse mapping
CODE_TO_NAME = {}
for _name, _code in NAME_TO_CODE.items():
    if _code not in CODE_TO_NAME:
        CODE_TO_NAME[_code] = _name


def code_for(name: str) -> int | None:
    """Get Linux key code for a friendly name."""
    return NAME_TO_CODE.get(name.lower())


def name_for(code: int) -> str:
    """Get friendly name for a Linux key code."""
    return CODE_TO_NAME.get(code, f"0x{code:02x}")
