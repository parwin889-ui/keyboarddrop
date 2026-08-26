using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace KeyboardDrop;

public enum KeyActionType
{
    Remap,
    App,
    Command,
    Ssh,
    File,
    Script,
    Screenshot,
    Url,
    Volume,
    Media,
    Text,
    System
}

public class KeyAction
{
    public KeyActionType Type { get; set; }
    public int RemapCode { get; set; }
    public string Target { get; set; } = "";

    public bool IsRemap => Type == KeyActionType.Remap;

    public string Description
    {
        get
        {
            return Type switch
            {
                KeyActionType.Remap => $"-> {KeyMap.NameFor(RemapCode)}",
                KeyActionType.App => $"-> App: {System.IO.Path.GetFileNameWithoutExtension(Target)}",
                KeyActionType.Command => $"-> Cmd: {(Target.Length > 30 ? Target[..27] + "..." : Target)}",
                KeyActionType.Ssh => $"-> SSH: {Target}",
                KeyActionType.File => $"-> File: {System.IO.Path.GetFileName(Target)}",
                KeyActionType.Script => $"-> Script: {System.IO.Path.GetFileName(Target)}",
                KeyActionType.Screenshot => $"-> Screenshot: {Target}",
                KeyActionType.Url => $"-> URL: {Target}",
                KeyActionType.Volume => $"-> Volume: {Target}",
                KeyActionType.Media => $"-> Media: {Target}",
                KeyActionType.Text => $"-> Text: {(Target.Length > 20 ? Target[..17] + "..." : Target)}",
                KeyActionType.System => $"-> System: {Target}",
                _ => "-> ???"
            };
        }
    }

    public void Execute()
    {
        switch (Type)
        {
            case KeyActionType.Remap:
                break;

            case KeyActionType.App:
                Process.Start(new ProcessStartInfo { FileName = Target, UseShellExecute = true });
                break;

            case KeyActionType.Command:
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = $"/c {Target}",
                    UseShellExecute = false,
                    CreateNoWindow = true
                });
                break;

            case KeyActionType.Ssh:
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = $"/k ssh {Target}",
                    UseShellExecute = true
                });
                break;

            case KeyActionType.File:
                Process.Start(new ProcessStartInfo { FileName = Target, UseShellExecute = true });
                break;

            case KeyActionType.Script:
                Process.Start(new ProcessStartInfo { FileName = Target, UseShellExecute = true });
                break;

            case KeyActionType.Screenshot:
                ExecuteScreenshot(Target);
                break;

            case KeyActionType.Url:
                Process.Start(new ProcessStartInfo { FileName = Target, UseShellExecute = true });
                break;

            case KeyActionType.Volume:
                ExecuteVolume(Target);
                break;

            case KeyActionType.Media:
                ExecuteMedia(Target);
                break;

            case KeyActionType.Text:
                Task.Run(() => ExecuteText(Target));
                break;

            case KeyActionType.System:
                ExecuteSystem(Target);
                break;
        }
    }

    private void ExecuteScreenshot(string mode)
    {
        var timestamp = System.DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss");
        var path = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.Desktop),
            $"Screenshot_{timestamp}.png");

        var args = mode.ToLowerInvariant() switch
        {
            "region" or "selection" => $"/c powershell -command \"Add-Type -AssemblyName System.Windows.Forms; $r = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; System.Drawing.Bitmap($r.Width, $r.Height)\"",
            "clipboard" or "clip" => "/c echo Screenshot to clipboard not implemented on Windows yet",
            _ => $"/c powershell -command \"Add-Type -AssemblyName System.Drawing; $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height); $g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($screen.X, $screen.Y, 0, 0, $bmp.Size); $g.Dispose(); $bmp.Save('{path}')\""
        };
        Process.Start(new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = args,
            UseShellExecute = false,
            CreateNoWindow = true
        });
    }

    private void ExecuteVolume(string action)
    {
        var args = action.ToLowerInvariant() switch
        {
            "up" => "/c nircmd.exe changesysvolume 5000",
            "down" => "/c nircmd.exe changesysvolume -5000",
            "mute" => "/c nircmd.exe mutesysvolume 1",
            "unmute" => "/c nircmd.exe mutesysvolume 0",
            _ => ""
        };
        if (!string.IsNullOrEmpty(args))
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = args,
                UseShellExecute = false,
                CreateNoWindow = true
            });
        }
    }

    private void ExecuteMedia(string action)
    {
        int vk = action.ToLowerInvariant() switch
        {
            "play" or "playpause" or "pause" => 0xB3,
            "next" or "next_track" => 0xB0,
            "prev" or "previous" or "prev_track" => 0xB1,
            "stop" => 0xB2,
            _ => -1
        };
        if (vk >= 0)
        {
            NativeMethods.keybd_event((byte)vk, 0, 0, System.IntPtr.Zero);
            NativeMethods.keybd_event((byte)vk, 0, NativeMethods.KEYEVENTF_KEYUP, System.IntPtr.Zero);
        }
    }

    private void ExecuteText(string text)
    {
        foreach (char c in text)
        {
            short vk = NativeMethods.VkKeyScan(c);
            if (vk != -1)
            {
                bool shift = (vk & 0x100) != 0;
                if (shift)
                    NativeMethods.keybd_event(0xA0, 0, 0, System.IntPtr.Zero); // shift down

                NativeMethods.keybd_event((byte)(vk & 0xFF), 0, 0, System.IntPtr.Zero);
                NativeMethods.keybd_event((byte)(vk & 0xFF), 0, NativeMethods.KEYEVENTF_KEYUP, System.IntPtr.Zero);

                if (shift)
                    NativeMethods.keybd_event(0xA0, 0, NativeMethods.KEYEVENTF_KEYUP, System.IntPtr.Zero); // shift up
            }
            System.Threading.Thread.Sleep(20);
        }
    }

    private void ExecuteSystem(string action)
    {
        var args = action.ToLowerInvariant() switch
        {
            "sleep" => "/c rundll32.exe powrprof.dll,SetSuspendState 0,1,0",
            "lock" => "/c rundll32.exe user32.dll,LockWorkStation",
            "restart" => "/c shutdown /r /t 0",
            "shutdown" => "/c shutdown /s /t 0",
            "logout" => "/c shutdown /l",
            _ => ""
        };
        if (!string.IsNullOrEmpty(args))
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = args,
                UseShellExecute = false,
                CreateNoWindow = true
            });
        }
    }

    public static KeyAction? FromConfig(object value)
    {
        if (value is string str)
        {
            var code = KeyMap.CodeFor(str);
            if (code == null)
            {
                System.Console.WriteLine($"  [warning] unknown target key: {str}");
                return null;
            }
            return new KeyAction { Type = KeyActionType.Remap, RemapCode = code.Value };
        }

        if (value is System.Text.Json.JsonElement el && el.ValueKind == System.Text.Json.JsonValueKind.Object)
        {
            string? type = null;
            string? target = null;
            foreach (var prop in el.EnumerateObject())
            {
                if (prop.Name == "type") type = prop.Value.GetString();
                if (prop.Name == "target") target = prop.Value.GetString();
            }

            if (type == null || target == null)
            {
                System.Console.WriteLine("  [warning] invalid action config");
                return null;
            }

            return type.ToLowerInvariant() switch
            {
                "remap" or "key" => KeyMap.CodeFor(target) is int c
                    ? new KeyAction { Type = KeyActionType.Remap, RemapCode = c }
                    : null,
                "app" => new KeyAction { Type = KeyActionType.App, Target = target },
                "command" or "cmd" => new KeyAction { Type = KeyActionType.Command, Target = target },
                "ssh" => new KeyAction { Type = KeyActionType.Ssh, Target = target },
                "file" => new KeyAction { Type = KeyActionType.File, Target = target },
                "script" => new KeyAction { Type = KeyActionType.Script, Target = target },
                "screenshot" or "screen" => new KeyAction { Type = KeyActionType.Screenshot, Target = target },
                "url" or "web" => new KeyAction { Type = KeyActionType.Url, Target = target },
                "volume" => new KeyAction { Type = KeyActionType.Volume, Target = target },
                "media" => new KeyAction { Type = KeyActionType.Media, Target = target },
                "text" or "type" => new KeyAction { Type = KeyActionType.Text, Target = target },
                "system" => new KeyAction { Type = KeyActionType.System, Target = target },
                _ => null
            };
        }

        return null;
    }
}
