using System;
using System.Linq;
using System.Runtime.InteropServices;

public class Program
{
    public delegate bool EnumWC(IntPtr hwnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int EnumWindows(EnumWC lpEnumFunc, IntPtr lParam);

    // Define the implementation of the delegate; here, we simply output the window handle.
    public static bool OutputWindow(IntPtr hwnd, IntPtr lParam)
    {
        Console.WriteLine(hwnd.ToInt64());
        return true;
    }

    [DllImport("kernel32.dll")]
    public static extern void GetSystemTime(SystemTime systemTime);

    [StructLayout(LayoutKind.Sequential)]
    public class SystemTime
    {
        public ushort Year;
        public ushort Month;
        public ushort DayOfWeek;
        public ushort Day;
        public ushort Hour;
        public ushort Minute;
        public ushort Second;
        public ushort Milsecond;
    }

    public static void Main(string[] args) =>
        // Invoke the method; note the delegate as a first parameter.
        EnumWindows(OutputWindow, IntPtr.Zero);
}