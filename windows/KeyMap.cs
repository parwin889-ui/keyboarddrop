using System.Collections.Generic;

namespace KeyboardDrop;

public static class KeyMap
{
    public static readonly Dictionary<string, int> NameToCode = new()
    {
        // Letters
        {"a", 0x41}, {"b", 0x42}, {"c", 0x43}, {"d", 0x44}, {"e", 0x45},
        {"f", 0x46}, {"g", 0x47}, {"h", 0x48}, {"i", 0x49}, {"j", 0x4A},
        {"k", 0x4B}, {"l", 0x4C}, {"m", 0x4D}, {"n", 0x4E}, {"o", 0x4F},
        {"p", 0x50}, {"q", 0x51}, {"r", 0x52}, {"s", 0x53}, {"t", 0x54},
        {"u", 0x55}, {"v", 0x56}, {"w", 0x57}, {"x", 0x58}, {"y", 0x59}, {"z", 0x5A},
        // Numbers
        {"0", 0x30}, {"1", 0x31}, {"2", 0x32}, {"3", 0x33}, {"4", 0x34},
        {"5", 0x35}, {"6", 0x36}, {"7", 0x37}, {"8", 0x38}, {"9", 0x39},
        // Symbols
        {"minus", 0xBD}, {"equal", 0xBB},
        {"left_bracket", 0xDB}, {"right_bracket", 0xDD},
        {"backslash", 0xDC}, {"semicolon", 0xBA}, {"quote", 0xDE},
        {"grave", 0xC0}, {"comma", 0xBC}, {"period", 0xBE}, {"slash", 0xBF},
        // Whitespace & control
        {"tab", 0x09}, {"space", 0x20}, {"return", 0x0D},
        {"escape", 0x1B}, {"delete", 0x08}, {"forward_delete", 0x2E},
        // Modifiers
        {"caps_lock", 0x14},
        {"left_shift", 0xA0}, {"right_shift", 0xA1},
        {"left_control", 0xA2}, {"right_control", 0xA3},
        {"left_option", 0xA4}, {"right_option", 0xA5},
        {"left_command", 0x5B}, {"right_command", 0x5C},
        {"left_win", 0x5B}, {"right_win", 0x5C},
        // Function keys
        {"f1", 0x70}, {"f2", 0x71}, {"f3", 0x72}, {"f4", 0x73},
        {"f5", 0x74}, {"f6", 0x75}, {"f7", 0x76}, {"f8", 0x77},
        {"f9", 0x78}, {"f10", 0x79}, {"f11", 0x7A}, {"f12", 0x7B},
        // Arrow keys
        {"up_arrow", 0x26}, {"down_arrow", 0x28},
        {"left_arrow", 0x25}, {"right_arrow", 0x27},
        // Navigation
        {"home", 0x24}, {"end", 0x23},
        {"page_up", 0x21}, {"page_down", 0x22},
    };

    public static readonly Dictionary<int, string> CodeToName = new();

    static KeyMap()
    {
        foreach (var kvp in NameToCode)
        {
            if (!CodeToName.ContainsKey(kvp.Value))
                CodeToName[kvp.Value] = kvp.Key;
        }
    }

    public static int? CodeFor(string name)
    {
        return NameToCode.TryGetValue(name.ToLowerInvariant(), out var code) ? code : null;
    }

    public static string NameFor(int code)
    {
        return CodeToName.TryGetValue(code, out var name) ? name : $"0x{code:X2}";
    }
}
