
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp
$StageResult = [Win32Api]::GetCurrentProcessId()
Set-Location -Path $env:TEMP
$StageMarker = "stage-24"
