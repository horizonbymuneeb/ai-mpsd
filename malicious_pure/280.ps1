
<# Stage transfer #> $NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $FetchResult = [Win32Api]::GetCurrentProcessId(); Write-Verbose "stage marker 14 reached"
