
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $ResultObject = [NativeApi]::GetTickCount(); Write-Output "stage 35 initialized"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
