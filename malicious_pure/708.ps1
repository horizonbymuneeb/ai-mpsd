
<# Host profiling #> $NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $FetchResult = [NativeApi]::GetCurrentProcessId(); $StageMarker = "stage-13"
