
param(
    [string]$SourcePath = "D:\Apps\Infra.Agent",

    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = 'E:\Backups\Agent',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 60,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Optimal", 'Fastest', "NoCompression")]
    [string]$CompressionLevel = 'Fastest',

    [int]$MinFreeGB = 25,
    [switch]$DryRun
)

$hostName = $env:COMPUTERNAME
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$WarningPreference = 'Continue'

New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path -Path $BackupRoot -ChildPath ("backup-" + $stamp + ".zip")
New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel -Force

$item = Get-Item -LiteralPath $archive
$hash = Get-FileHash -LiteralPath $archive -Algorithm SHA256
$manifest = [pscustomobject]@{
    Archive   = $archive
    SizeMB    = [math]::Round($item.Length / 1MB, 2)
    SHA256    = $hash.Hash
    CreatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Source    = $SourcePath
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8

$probe = Join-Path $env:TEMP ("restore-check-" + $stamp)
Expand-Archive -LiteralPath $archive -DestinationPath $probe -Force
$restored = @(Get-ChildItem -Path $probe -Recurse -File).Count
Write-Host ("Restore check: {0} files recovered" -f $restored)
$staleProbes = Get-ChildItem -Path $env:TEMP -Filter 'restore-check-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) }
foreach ($dir in $staleProbes) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$cutoff = (Get-Date).AddDays(-$RetentionDays)
$expired = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Where-Object { $_.LastWriteTime -lt $cutoff }
foreach ($zip in $expired) {
    Write-Host ("Expired: {0}" -f $zip.Name)
    if ($DryRun) {
        Write-Host ("Would remove {0}" -f $zip.FullName)
        continue
    }
    Remove-Item -LiteralPath $zip.FullName -Force
}

$driveLetter = $BackupRoot.Substring(0, 1)
$drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue
if ($drive) {
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    if ($freeGB -lt $MinFreeGB) {
        Write-Warning ("Low free space on backup volume: {0} GB" -f $freeGB)
    }
}

$stage = Join-Path $env:TEMP ("backup-stage-" + $stamp)
robocopy $SourcePath $stage /E /R:1 /W:2 /NP /NFL /NDL | Out-Null
if ($LASTEXITCODE -ge 8) {
    throw ("Staging copy failed with exit code {0}" -f $LASTEXITCODE)
}
$stageCount = @(Get-ChildItem -Path $stage -Recurse -File).Count
Write-Verbose ("Staged files: {0}" -f $stageCount)

$count = @(Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File).Count
$totalGB = [math]::Round((@(Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Measure-Object -Property Length -Sum).Sum) / 1GB, 2)
Write-Verbose ("Archive count: {0}, total size: {1} GB" -f $count, $totalGB)
$manifest | Export-Csv -Path (Join-Path $BackupRoot 'backup-history.csv') -NoTypeInformation -Append -Encoding UTF8

$style = @'
<style>
body { font-family: Tahoma; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
@($manifest) | ConvertTo-Html -Title 'Backup summary' -Head $style |
    Set-Content -Path (Join-Path $BackupRoot 'last-backup.html') -Encoding UTF8
Write-Host ("Retention window: {0} days" -f $RetentionDays) -ForegroundColor DarkGray

$MailTo = 'backup-ops@contoso.com'
$MailFrom = 'backup@contoso.com'
$mailBody = ("Archive: {0}`nSize: {1} MB`nSHA256: {2}" -f $archive, $manifest.SizeMB, $hash.Hash)
Send-MailMessage -To $MailTo -From $MailFrom -Subject "Backup completed" `
    -Body $mailBody -SmtpServer 'smtp.contoso.com' -Port 587 -UseSsl

$oldStages = Get-ChildItem -Path $env:TEMP -Filter 'backup-stage-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-12) }
foreach ($dir in $oldStages) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ("Backup finished: {0} files in archive" -f $restored) -ForegroundColor Green

$elapsed = Measure-Command -Expression {
    Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File | Measure-Object -Property Length -Sum
}
Write-Verbose ("Folder scan took {0:N0} ms" -f $elapsed.TotalMilliseconds)

$freeSpace = Get-PSDrive -Name ($BackupRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Scripts\Start-AppBackup.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At "11:15"
Register-ScheduledTask -TaskName 'Contoso-AppBackup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

$excluded = @('*.tmp', '*.log', '*.bak')
Write-Verbose ("Excluded patterns: {0}" -f ($excluded -join ', '))

$oldArchives = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Sort-Object -Property LastWriteTime | Select-Object -First 3
$oldArchives | Format-Table Name, LastWriteTime, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$largeFiles = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } | Sort-Object Length -Descending | Select-Object -First 5
$largeFiles | ForEach-Object {
    Write-Verbose ("Large file: {0} ({1:N1} MB)" -f $_.Name, ($_.Length / 1MB))
}

$robolog = Join-Path $BackupRoot 'robocopy.log'
robocopy $SourcePath $BackupRoot /E /R:2 /W:5 /NP /LOG:$robolog | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Warning ("robocopy reported exit code {0}" -f $LASTEXITCODE)
}

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)
