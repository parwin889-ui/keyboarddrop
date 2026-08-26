using System.Runtime.InteropServices;

namespace KeyboardDrop;

internal static class NativeMethods
{
    public const uint KEYEVENTF_KEYUP = 0x0002;

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, System.IntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern short VkKeyScan(char ch);
}
