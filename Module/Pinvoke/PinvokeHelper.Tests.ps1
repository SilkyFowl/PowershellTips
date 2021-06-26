using namespace System.Runtime.InteropServices

BeforeAll {
    Import-Module $PSScriptRoot\PinvokeHelper.psm1
}

Describe "Create PInvoke" {
    Context "When callback" {
        It "should work" {
            $EnumWC = Add-DelegateType EnumWC bool System.IntPtr, System.IntPtr
            $EnumWC | Should -BeOfType [Type]

            $M = Add-PinvokeType -TypeName M -ProcName EnumWindows -EntryPoint EnumWindows -ModuleFile User32.dll -ReturnType int -ParameterTypes $EnumWC, IntPtr -CallingConvention StdCall -CharSet Unicode
            $psMethod = New-PsMethod bool '[System.IntPtr]$hwnd', '[System.IntPtr]$lParam' {
                return $true
            }
            $M::EnumWindows($psMethod, [Intptr]::Zero)

        }
    }

    Context "GetSystemTime" {
        It "should failed" {
            {
                [StructLayoutAttribute([LayoutKind]::Sequential)]
                class SystemTime {
                    [ushort]$Year
                    [ushort]$Month
                    [ushort]$DayOfWeek
                    [ushort]$Day
                    [ushort]$Hour
                    [ushort]$Minute
                    [ushort]$Second
                    [ushort]$Milsecond
                }
                $time = [SystemTime]::new()
                $m = Add-PinvokeType M GetSystemTime GetSystemTime kernel32.dll void  ([SystemTime].MakeByRefType()) Winapi Auto
                $m::GetSystemTime([ref]$time)
                10
            } | Should -Throw '*"The invoked member is not supported in a dynamic assembly."*'
        }

        It "should work" {
            {
               $SystemTime= Add-Type @'
using System;
using System.Linq;
using System.Runtime.InteropServices;

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
'@ -PassThru

                Add-Type @'
using System;
using System.Linq;
using System.Runtime.InteropServices;

public class Native
{
    [DllImport("kernel32.dll")]
    public static extern void GetSystemTime(SystemTime systemTime);
}
'@ -ReferencedAssemblies $SystemTime.Assembly
                $time = [SystemTime]::new()
            } | Should -Throw '*"The invoked member is not supported in a dynamic assembly."*'
        }

    }

    Context "GetEnvironmentVariableW" {
        It "should work" {
            $M = Add-PinvokeType M GetEnvironmentVariable GetEnvironmentVariableW kernel32.dll int string, System.Text.StringBuilder, int StdCall Unicode
            [System.Text.StringBuilder]$sb = $null
            $m.gettype()
            $mi = $M.GetMethod('GetEnvironmentVariable')
            $mi.Invoke($null, @(("COMPUTERNAME", $sb, 0)))
            $M::GetEnvironmentVariable("COMPUTERNAME", $sb, 0)
        }
    }
}