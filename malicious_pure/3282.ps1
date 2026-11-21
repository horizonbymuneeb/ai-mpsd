
<# Remote fetch #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [Win32Api]::GetCurrentThreadId(); $ProgressPreference = "SilentlyContinue"
