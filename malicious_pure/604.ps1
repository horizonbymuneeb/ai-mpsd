
# Encoded launcher
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp
$FetchResult = [NativeMethods]::GetCurrentProcessId()
$AmsiMarker = "amsiInitFailed"
$ProgressPreference = "SilentlyContinue"
Write-Verbose "stage marker 5 reached"
