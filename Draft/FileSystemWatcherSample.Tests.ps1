using namespace System.IO

Describe "Subscribe FileSystemWatcher's events" {
    Context "Changed" {
        BeforeEach {
            1..5 | Set-Content Testdrive:/test.txt
            $watcher = [FileSystemWatcher]::new((Convert-Path Testdrive:))
            $watcher.Filter="*.txt"

            $beforeErrorCount = $Error.Count
        }
        It "By ScriptBlock" {
            $action = {
                Get-Variable -Scope 0 | Tee-Object Testdrive:/changed.log -Append | Out-Host
                $sender | Format-List  | Tee-Object Testdrive:/changed.log -Append | Out-Host
                $eventArgs | Format-List  | Tee-Object Testdrive:/changed.log -Append | Out-Host
            }
            Register-ObjectEvent $watcher -EventName Changed -SourceIdentifier changedEvent -Action $action
            6..10 | Set-Content Testdrive:/test.txt

            $Error.Count | should -be $beforeErrorCount
        }
        It "Create PsEvent" {
            $action = {
                New-Event -SourceID "PowerShell.FileChanged" -Sender $sender -EventArguments $event > $null
            }
            Register-ObjectEvent $watcher -EventName Changed -SourceIdentifier changedEvent -Action $action

            Register-EngineEvent psChangedEvent -Action {
                Get-Variable -Scope 0 | Tee-Object Testdrive:/changed.log -Append | Out-Host
                $sender | Format-List  | Tee-Object Testdrive:/changed.log -Append | Out-Host
                $eventArgs | Format-List  | Tee-Object Testdrive:/changed.log -Append | Out-Host
            }
            6..10 | Set-Content Testdrive:/test.txt
            Unregister-Event psChangedEvent

            $Error.Count | should -be $beforeErrorCount
        }
        It "Start Thread Job" {
            $action = {
                Get-Variable -Scope 0  | Start-ThreadJob {
                    "event fired."
                    $input | Tee-Object Testdrive:/changed.log -Append | Out-Host
                    Get-Variable -Scope 0 | Tee-Object "$TestDrive/changed.log" -Append | Out-Host
                    $sender | Format-List  | Tee-Object "$TestDrive/changed.log" -Append | Out-Host
                    $eventArgs | Format-List  | Tee-Object "$TestDrive/changed.log" -Append | Out-Host
                } -Name watcherJob
            }
            Register-ObjectEvent $watcher -EventName Changed -SourceIdentifier changedEvent -Action $action
            6..10 | Set-Content Testdrive:/test.txt
            get-job watcherJob | Receive-Job -Wait -AutoRemoveJob | Tee-Object Testdrive:/changed.log -Append | Out-Host

            $Error.Count | should -be $beforeErrorCount
        }

        AfterEach {
            Unregister-Event changedEvent
            $watcher.Dispose()
        }
    }
}


