#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BaseUri = "https://api.contoso.com/v1",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 5,

    [int]$TimeoutSec = 45,

    [int]$PageSize = 25,
    [string]$ReportPath = 'C:\Reports\api-servers-2026-10-13.csv'
)

$ErrorActionPreference = 'Stop'

$hostName = $env:COMPUTERNAME
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
    Write-Verbose ("Collected {0} records" -f @($records).Count)
}
$summary = $records | Group-Object -Property status | ForEach-Object {
    [pscustomobject]@{
        Status = $_.Name
        Count  = $_.Count
    }
}
$summary | Format-Table -AutoSize

$records | Select-Object id, name, status | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$summary | Export-Csv -Path $ReportPath.Replace('.csv', '-summary.csv') -NoTypeInformation -Encoding UTF8

$newTag = @{ tags = @('inventory', 'automated') }
try {
    $tagged = Invoke-ContosoApi -Path '/servers/tags' -Method Post -Body $newTag
    Write-Verbose ("Tag request returned {0}" -f $tagged.status)
}
catch {
    Write-Warning ("Tagging skipped: {0}" -f $_.Exception.Message)
}

$style = @'
<style>
body { font-family: Arial; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$summary | ConvertTo-Html -Title 'API inventory summary' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$MailTo = "api-ops@contoso.com"
$MailFrom = 'api-report@contoso.com'
$mailBody = "Inventory run finished with {0} records" -f @($records).Count
Send-MailMessage -To $MailTo -From $MailFrom -Subject 'API inventory' -Body $mailBody -SmtpServer "smtp.contoso.com" -Port 25

Write-Host ("API inventory complete: {0} records" -f @($records).Count) -ForegroundColor Green
Write-Verbose ("Elapsed requests: {0}" -f [math]::Ceiling(@($records).Count / $PageSize))

$baseUriHost = ([uri]$BaseUri).Host
Write-Verbose ("Target host: {0}" -f $baseUriHost)

$rateLimit = $null
if ($rateLimit) {
    Write-Verbose ("Remaining calls: {0}" -f $rateLimit)
}

$tokenLength = $ApiKey.Length
Write-Verbose ("API key length: {0}" -f $tokenLength)

$endpoints = @('/servers', '/servers/tags', '/health')
$endpoints | ForEach-Object { Write-Verbose ("Endpoint: {0}" -f $_) }

$retryCount = @($records).Count - @($records | Select-Object -Unique) .Count
Write-Verbose ("Duplicate ids skipped: {0}" -f $retryCount)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
