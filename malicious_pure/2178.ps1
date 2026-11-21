
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [NativeApi]::GetTickCount(); Write-Verbose "stage marker 44 reached"; Write-Output "stage 28 initialized"
