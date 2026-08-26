using System;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

namespace KeyboardDrop;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();

        var app = new KeyboardDropApp();
        Application.Run();
    }
}

internal class KeyboardDropApp : ApplicationContext
{
    private readonly NotifyIcon _trayIcon;
    private readonly KeyboardHook _hook = new();
    private readonly ContextMenuStrip _menu = new();
    private string _configPath;
    private Config _config;

    public KeyboardDropApp()
    {
        _configPath = ResolveConfigPath();
        LoadConfig();
        _hook.Start();

        _trayIcon = new NotifyIcon
        {
            Icon = CreateKeyboardIcon(),
            Text = "KeyboardDrop",
            Visible = true,
            ContextMenuStrip = _menu
        };

        RebuildMenu();
    }

    private string ResolveConfigPath()
    {
        var appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        var configDir = Path.Combine(appData, "KeyboardDrop");
        var configPath = Path.Combine(configDir, "config.json");

        if (!File.Exists(configPath))
        {
            Config.CreateDefault(configPath);
            Console.WriteLine($"keyboarddrop: created default config at {configPath}");
        }

        return configPath;
    }

    private void LoadConfig()
    {
        _config = Config.Load(_configPath);
        if (_config != null)
        {
            var actions = _config.ToKeyActions();
            _hook.UpdateActions(actions);
            Console.WriteLine($"keyboarddrop: loaded {actions.Count} mapping(s) from {_configPath}");
        }
    }

    private void RebuildMenu()
    {
        _menu.Items.Clear();

        var status = _hook.IsActive ? "● Active" : "○ Paused";
        var statusItem = new ToolStripMenuItem(status) { Enabled = false };
        _menu.Items.Add(statusItem);

        _menu.Items.Add(new ToolStripSeparator());

        var toggleItem = new ToolStripMenuItem(_hook.IsActive ? "Pause" : "Resume", null, (_, _) => Toggle());
        _menu.Items.Add(toggleItem);

        var reloadItem = new ToolStripMenuItem("Reload Config", null, (_, _) => ReloadConfig());
        _menu.Items.Add(reloadItem);

        _menu.Items.Add(new ToolStripSeparator());

        if (_config != null && _config.RawMappings.Count > 0)
        {
            var mappingsItem = new ToolStripMenuItem("Mappings");
            foreach (var desc in _config.Describe())
            {
                mappingsItem.DropDownItems.Add(desc).Enabled = false;
            }
            _menu.Items.Add(mappingsItem);
        }
        else
        {
            var item = _menu.Items.Add("No mappings configured");
            item.Enabled = false;
        }

        _menu.Items.Add(new ToolStripSeparator());

        _menu.Items.Add($"Config: {_configPath}", null, (_, _) => RevealConfig());
        _menu.Items.Add("Quit KeyboardDrop", null, (_, _) => Quit());
    }

    private void Toggle()
    {
        if (_hook.IsActive)
            _hook.Stop();
        else
            _hook.Start();
        RebuildMenu();
    }

    private void ReloadConfig()
    {
        LoadConfig();
        RebuildMenu();
    }

    private void RevealConfig()
    {
        if (File.Exists(_configPath))
        {
            var args = $"/select,\"{_configPath}\"";
            System.Diagnostics.Process.Start("explorer.exe", args);
        }
    }

    private void Quit()
    {
        _hook.Stop();
        _trayIcon.Visible = false;
        Application.Exit();
    }

    private Icon CreateKeyboardIcon()
    {
        // Draw a keyboard icon programmatically
        var bmp = new Bitmap(32, 32);
        using var g = Graphics.FromImage(bmp);
        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

        // Background: dark gray keyboard body
        using var bodyBrush = new SolidBrush(Color.DarkGray);
        g.FillRectangle(bodyBrush, 2, 8, 28, 18);

        // Keys: light gray
        using var keyBrush = new SolidBrush(Color.LightGray);
        var keyW = 4f;
        var keyH = 3f;
        var gap = 1f;
        var startX = 4f;
        var startY = 10f;
        for (int row = 0; row < 3; row++)
        {
            for (int col = 0; col < 6; col++)
            {
                var x = startX + col * (keyW + gap);
                var y = startY + row * (keyH + gap);
                g.FillRectangle(keyBrush, x, y, keyW, keyH);
            }
        }

        var handle = bmp.GetHicon();
        return Icon.FromHandle(handle);
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _hook.Dispose();
            _trayIcon.Dispose();
            _menu.Dispose();
        }
        base.Dispose(disposing);
    }
}
