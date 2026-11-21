<#
.SYNOPSIS
    Calls the Contoso inventory API with retry and exports the server list.
.PARAMETER BaseUri
    Defaults to the value configured for this host.
.PARAMETER MaxRetries
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Get-ApiServers.ps1 -PageSize 100
.EXAMPLE
    .\Get-ApiServers.ps1 -Verbose
.NOTES
    Author: Infra Automation
    Last updated: 2025-06-17
#>

$BaseUri = 'https://api.contoso.com/v1'
$MaxRetries = 5
$TimeoutSec = 15
$PageSize = 100
$ReportPath = 'C:\Reports\api-servers-2025-06-19.csv'

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
$records | Select-Object id, name, status | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
