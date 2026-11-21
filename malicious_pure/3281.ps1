
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $TransferResult = [NativeApi]::GetCurrentProcessId(); Write-Output "stage 33 initialized"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
