
$ErrorActionPreference = "Stop"

$OutputPath = 'C:\ProgramData\Contoso\InfraRelay\config.json'
$Environment = "Dev"
$ApiPort = 8443
$NodeCount = 2
$Force = $false


$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'InfraRelay'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
$NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [Win32Api]::GetVersion(); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
