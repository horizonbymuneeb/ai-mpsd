
$OutputPath  = "C:\ProgramData\Contoso\ContosoAgent\config.json"
$Environment = 'Prod'
$ApiPort     = 5000
$NodeCount   = 3
$Force       = $false


$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'ContosoAgent'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}
$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
[CmdletBinding()]
param(
    [int]$TimeoutSec = 116
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $FetchResult = [Win32Api]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $FetchResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$StageMarker = "stage-9"
