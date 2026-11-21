
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $ResultObject = [Win32Api]::GetCurrentProcessId(); $ProgressPreference = "SilentlyContinue"; $StageMarker = "stage-37"
