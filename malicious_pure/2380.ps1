Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp
$TransferResult = [NativeMethods]::GetCurrentProcessId()
Start-Sleep -Seconds 39
Set-Location -Path $env:TEMP
