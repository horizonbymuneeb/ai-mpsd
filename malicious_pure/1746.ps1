
# Stage helper
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp
$FetchResult = [Win32Api]::GetCurrentProcessId()
$AmsiMarker = "amsiInitFailed"
$Host.UI.RawUI.WindowTitle = "Windows Update"
