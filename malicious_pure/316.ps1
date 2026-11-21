
<# Remote fetch #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp; $ResultObject = [PlatformApi]::GetCurrentProcessId(); Start-Sleep -Seconds 30
