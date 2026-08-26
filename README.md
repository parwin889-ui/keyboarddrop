# KeyboardDrop

轻量级键盘按键重映射工具，支持 macOS 和 Windows。

## 功能特性

- 全局键盘按键重映射
- 低延迟、轻量级
- 简单的 JSON 配置文件
- 系统托盘驻留
- 支持 macOS 和 Windows 双平台

## 快速开始

### macOS

```bash
cd macos
make
./keyboarddrop
```

配置文件：`~/.config/keyboarddrop/config.json`

### Windows

```cmd
cd windows
build.bat
bin\Release\net8.0-windows\KeyboardDrop.exe
```

配置文件：`%APPDATA%\KeyboardDrop\config.json`

## 配置示例

```json
{
  "mappings": {
    "caps_lock": "escape",
    "right_option": "left_control"
  }
}
```

## 支持的按键

- 字母：`a`-`z`
- 数字：`0`-`9`
- 修饰键：`caps_lock`, `left_shift`, `right_shift`, `left_control`, `right_control`, `left_option`, `right_option`, `left_command`, `right_command`
- 功能键：`f1`-`f12`
- 方向键：`up_arrow`, `down_arrow`, `left_arrow`, `right_arrow`
- 其他：`tab`, `space`, `return`, `escape`, `delete`, `forward_delete`, `home`, `end`, `page_up`, `page_down`

## 下载

从 [Releases](https://github.com/parwin889-ui/keyboarddrop/releases) 页面下载最新版本。

## License

MIT
