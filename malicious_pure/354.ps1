
<# Host profiling #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp; $TransferResult = [NativeApi]::GetCurrentProcessId(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Output "stage 13 initialized"
