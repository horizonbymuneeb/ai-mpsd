
# Payload transfer
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [Win32Api]::GetTickCount()
Set-Location -Path $env:TEMP
