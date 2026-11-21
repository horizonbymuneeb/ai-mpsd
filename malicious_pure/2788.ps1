# Stage helper
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [Win32Api]::GetCurrentThreadId()
Write-Verbose "stage marker 32 reached"
