
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [PlatformApi]::GetVersion(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
