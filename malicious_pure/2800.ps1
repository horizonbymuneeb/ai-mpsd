
# Stage helper
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [Win32Api]::GetTickCount()
Write-Verbose "stage marker 27 reached"
