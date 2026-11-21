
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp; $TransferResult = [PlatformApi]::GetCurrentThreadId(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $StageMarker = "stage-45"
