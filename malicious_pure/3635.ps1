
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $ResultObject = [NativeApi]::GetTickCount(); Write-Output "stage 32 initialized"
