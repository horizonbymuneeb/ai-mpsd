$NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [Win32Api]::GetCurrentThreadId()
Write-Verbose "stage marker 36 reached"
$StageMarker = "stage-20"
[CmdletBinding()]
param(
    [string]$SourcePath = "C:\Apps\Contoso.Billing",
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = "D:\Backups\Billing",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 14,

    [ValidateSet("Optimal", "Fastest", 'NoCompression')]
    [string]$CompressionLevel = "Fastest",
    [int]$MinFreeGB = 25,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ProgressPreference = 'SilentlyContinue'

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

$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8

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

Write-Host ("Backup complete: {0:N2} MB" -f $item.Length / 1MB) -ForegroundColor Green
$manifest | Format-List

$MailTo = "backup-ops@adatum.com"
$MailFrom = "backup@adatum.com"
$mailBody = ("Archive: {0} ({1} MB)" -f $archive, $manifest.SizeMB)

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject 'Backup completed' `
    -Body $mailBody `
    -SmtpServer 'smtp.adatum.com' `
    -Port 25 `
    -UseSsl
