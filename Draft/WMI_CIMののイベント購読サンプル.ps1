$action = {
    $e = $event.SourceEventArgs.NewEvent
    $parentID = 23920
    if (($e.ParentProcessID -eq $parentID) -and ($e.ProcessName -eq 'cmd.exe')) {
        Write-Host -Object "New Process Started"
        Write-Host  ($event.SourceEventArgs.NewEvent | Format-List | out-string)
        # stop-Process -Id $e.ProcessID -Force
    }
}
Register-CimIndicationEvent -ClassName 'Win32_ProcessStartTrace' -SourceIdentifier "ProcessStarted" -Action $action
$action = {
    $e = $event.SourceEventArgs.NewEvent
    if ((Get-Process -id $e.ParentProcessID).ProcessName -eq 'cmd') {
        Write-Host -Object "New Thread Started :"
        Write-Host  ($event.SourceEventArgs.NewEvent | out-string)
    }
}
Register-CimIndicationEvent -ClassName 'Win32_ThreadStartTrace ' -SourceIdentifier "ThreadStarted" -Action $action

$action = {
    $e = $event.SourceEventArgs.NewEvent
    $parentID = 23920
    if (($e.ParentProcessID -eq $parentID) -and ($e.ProcessName -eq 'cmd.exe')) {
        Write-Host -Object "New Module Started :"
        Write-Host  ($event.SourceEventArgs.NewEvent | out-string)
    }
}
Register-CimIndicationEvent -ClassName 'Win32_ModuleLoadTrace  ' -SourceIdentifier "ModuleStarted" -Action $action
Unregister-Event ProcessStarted
Unregister-Event ThreadStarted
Unregister-Event ModuleStarted