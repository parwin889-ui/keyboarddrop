# KeyboardDrop for Linux

全局键盘按键重映射工具的 Linux 版本，基于 `evdev` + `uinput` 实现。

## 要求

- Python 3.10+
- Linux (支持 uinput 的内核)
- Root 权限

## 安装

```bash
# 安装依赖
pip install -r requirements.txt

# 或直接安装 evdev
pip install evdev
```

## 使用

### 列出键盘设备

```bash
sudo python3 main.py --list-devices
```

### 运行

```bash
sudo python3 main.py
```

程序会自动检测键盘设备并创建虚拟键盘设备，所有按键经过重映射后通过虚拟键盘输出。

## 配置

配置文件路径：`~/.config/keyboarddrop/config.json`

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

## 工作原理

1. 读取物理键盘的输入事件 (`/dev/input/eventX`)
2. 以独占模式 (grab) 捕获键盘，阻止原始事件到达系统
3. 根据配置重映射按键
4. 通过 `uinput` 创建的虚拟键盘输出重映射后的按键

## 注意事项

- 需要 root 权限才能访问输入设备和 uinput
- 如果有多个键盘，程序会自动选择第一个包含字母键和回车键的设备
- 程序退出时会自动释放键盘 grab
