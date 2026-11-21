
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $FetchResult = [NativeMethods]::GetTickCount(); Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$ErrorActionPreference = 'Stop'
$OutputPath  = 'C:\ProgramData\Contoso\InfraRelay\config.json'
$Environment = 'Dev'
$ApiPort     = 9443
$NodeCount   = 2
$Force       = $false


$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'InfraRelay'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}
$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
