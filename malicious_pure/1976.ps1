
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [PlatformApi]::GetTickCount(); Remove-Item -Path "$env:TEMP\stage2.bin" -Force; Write-Verbose "stage marker 36 reached"
