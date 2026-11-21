Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }' -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [Win32Api]::GetTickCount()
Write-Output "stage 6 initialized"
$StageMarker = "stage-10"
