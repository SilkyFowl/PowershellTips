using namespace System.IO

Describe "イベントを購読" {
    Context "Changed" {
        BeforeAll {
            $watcher = [FileSystemWatcher]::new($PWD)
        }
        It "直接処理する" -Skip {
            $action = {
                Get-Variable -Scope 0 | Format-List | Out-Host
            }
            Register-ObjectEvent $watcher -EventName Changed -SourceIdentifier changedEvent -Action $action
        }
        It "新しくイベントを発行する" -Skip {
            $action = {
                New-Event -SourceID "PowerShell.FileChanged" -Sender $sender -EventArguments $event > $null
            }
            Register-ObjectEvent $watcher -EventName Changed -SourceIdentifier changedEvent -Action $action
        }
        It "Thread Jobを発行する" -Skip {
            $action = {
                # Get-Variable -Scope 0  | Start-ThreadJob { "event fired."; $input } -Name "watcherJob$(New-Guid)"
            }
            Register-ObjectEvent $watcher -EventName Changed -SourceIdentifier changedEvent -Action $action
        }

        AfterEach {
            Unregister-Event changedEvent
        }
    }
}


