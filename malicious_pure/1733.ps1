
# Stage helper
$NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$FetchResult = [Win32Api]::GetCurrentProcessId()
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
