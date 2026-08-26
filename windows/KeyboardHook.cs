using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace KeyboardDrop;

public class KeyboardHook : IDisposable
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_KEYUP = 0x0101;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int WM_SYSKEYUP = 0x0105;

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT
    {
        public int vkCode;
        public int scanCode;
        public int flags;
        public int time;
        public IntPtr dwExtraInfo;
    }

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    private IntPtr _hookId = IntPtr.Zero;
    private LowLevelKeyboardProc _proc;
    private Dictionary<int, KeyAction> _actions = new();
    private bool _isActive = false;

    public bool IsActive => _isActive;

    public void UpdateActions(Dictionary<int, KeyAction> actions)
    {
        _actions = actions;
    }

    public void Start()
    {
        if (_hookId != IntPtr.Zero)
            return;

        _proc = HookCallback;
        using var process = Process.GetCurrentProcess();
        using var module = process.MainModule;
        _hookId = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(module.ModuleName), 0);
        _isActive = _hookId != IntPtr.Zero;

        if (!_isActive)
            Console.Error.WriteLine("Failed to set keyboard hook.");
    }

    public void Stop()
    {
        if (_hookId != IntPtr.Zero)
        {
            UnhookWindowsHookEx(_hookId);
            _hookId = IntPtr.Zero;
        }
        _isActive = false;
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && _actions.Count > 0)
        {
            int msg = wParam.ToInt32();
            bool isKeyDown = msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN;
            bool isKeyUp = msg == WM_KEYUP || msg == WM_SYSKEYUP;

            if (isKeyDown || isKeyUp)
            {
                var kbStruct = Marshal.PtrToStructure<KBDLLHOOKSTRUCT>(lParam);
                int vkCode = kbStruct.vkCode;

                if (_actions.TryGetValue(vkCode, out var action))
                {
                    if (action.IsRemap)
                    {
                        // Key remap: simulate mapped key and suppress original
                        if (isKeyDown)
                            NativeMethods.keybd_event((byte)action.RemapCode, 0, 0, IntPtr.Zero);
                        else
                            NativeMethods.keybd_event((byte)action.RemapCode, 0, NativeMethods.KEYEVENTF_KEYUP, IntPtr.Zero);
                        return (IntPtr)1; // suppress
                    }
                    else
                    {
                        // Custom action: suppress key, execute on keyDown only
                        if (isKeyDown)
                        {
                            Task.Run(() => action.Execute());
                        }
                        return (IntPtr)1; // suppress both down and up
                    }
                }
            }
        }

        return CallNextHookEx(_hookId, nCode, wParam, lParam);
    }

    public void Dispose()
    {
        Stop();
    }
}
