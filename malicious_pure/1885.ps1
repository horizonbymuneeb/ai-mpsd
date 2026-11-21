Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }' -Language CSharp -ErrorAction SilentlyContinue
$FetchResult = [Win32Api]::GetTickCount()
$AmsiMarker = "amsiInitFailed"
Write-Verbose "stage marker 41 reached"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
