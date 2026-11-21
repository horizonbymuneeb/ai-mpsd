
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp -ErrorAction SilentlyContinue; $TransferResult = [NativeMethods]::GetCurrentProcessId(); $AmsiMarker = "amsiInitFailed"; $StageMarker = "stage-12"
