
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $ResultObject = [NativeMethods]::GetCurrentThreadId(); Write-Output "stage 8 initialized"
