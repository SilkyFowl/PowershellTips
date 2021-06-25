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
                $m = Add-PinvokeType M GetSystemTime GetSystemTime kernel32.dll void  ([SystemTime]) Winapi Unicode
                $m::GetSystemTime($time)
            } | Should -Throw '*"The invoked member is not supported in a dynamic assembly."*'
        }

    }
}