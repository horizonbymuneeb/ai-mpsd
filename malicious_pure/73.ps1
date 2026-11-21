# Payload transfer
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp
$TransferResult = [NativeApi]::GetCurrentProcessId()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
