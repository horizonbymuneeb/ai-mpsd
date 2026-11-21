$NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [Win32Api]::GetCurrentThreadId()
Write-Verbose "stage marker 36 reached"
$StageMarker = "stage-20"
