using namespace System.IO

Describe "Subscribe FileSystemWatcher's events" {
    Context "Changed" {
        BeforeAll {
            $watcher = [FileSystemWatcher]::new($PWD)
        }
        It "By ScriptBlock" -Skip {
            $action = {
                Get-Variable -Scope 0 | Format-List | Out-Host
            }
            Register-ObjectEvent $watcher -EventName Changed -SourceIdentifier changedEvent -Action $action
        }
        It "Create PsEvent" -Skip {
            $action = {
                New-Event -SourceID "PowerShell.FileChanged" -Sender $sender -EventArguments $event > $null
            }
            Register-ObjectEvent $watcher -EventName Changed -SourceIdentifier changedEvent -Action $action
        }
        It "Start Thread Job" -Skip {
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


