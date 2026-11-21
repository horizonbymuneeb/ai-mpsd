# Encoded launcher
$NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [Win32Api]::GetVersion()
Write-Verbose "stage marker 30 reached"
