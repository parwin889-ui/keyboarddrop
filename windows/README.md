# KeyboardDrop for Windows

## Requirements
- .NET 8 SDK (https://dotnet.microsoft.com/download)
- Windows 10/11

## Build
```cmd
build.bat
```
Or manually:
```cmd
dotnet build -c Release
```

## Run
```cmd
dotnet run -c Release
```
Or use the built exe:
```cmd
bin\Release\net8.0-windows\KeyboardDrop.exe
```

## Configuration
Config file: `%APPDATA%\KeyboardDrop\config.json`

```json
{
  "mappings": {
    "caps_lock": "escape",
    "right_win": "left_control"
  }
}
```

## Key Name Reference
- Letters: `a`-`z`
- Numbers: `0`-`9`
- Symbols: `minus`, `equal`, `left_bracket`, `right_bracket`, `backslash`, `semicolon`, `quote`, `grave`, `comma`, `period`, `slash`
- Whitespace: `tab`, `space`, `return`, `escape`, `delete`, `forward_delete`
- Modifiers: `caps_lock`, `left_shift`, `right_shift`, `left_control`, `right_control`, `left_option`(Alt), `right_option`, `left_win`, `right_win`
- Function keys: `f1`-`f12`
- Arrows: `up_arrow`, `down_arrow`, `left_arrow`, `right_arrow`
- Navigation: `home`, `end`, `page_up`, `page_down`

## How It Works
- Uses `SetWindowsHookEx` with `WH_KEYBOARD_LL` for system-wide keyboard hook
- Runs as a system tray application (no taskbar icon)
- Right-click tray icon for menu: Pause/Resume, Reload Config, Quit
