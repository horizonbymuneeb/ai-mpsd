<#
.SYNOPSIS
    Calls the Contoso inventory API with retry and exports the server list.
.DESCRIPTION
    Wraps Invoke-RestMethod in a retry helper that backs off on transient errors
    and gives up on client errors such as 401 or 404.
    Pages are followed through the nextLink property until the collection is
    exhausted, then the records are written to CSV.
.PARAMETER BaseUri
    Defaults to the value configured for this host.
#>

param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BaseUri = "https://api.internal.corp/v1",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 2,

    [int]$TimeoutSec = 45,
    [int]$PageSize = 100,
    [string]$ReportPath = "C:\Reports\api-servers-2026-08-14.csv"
)

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
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [NativeApi]::GetCurrentThreadId()
$ProgressPreference = "SilentlyContinue"
Write-Verbose "stage marker 30 reached"
