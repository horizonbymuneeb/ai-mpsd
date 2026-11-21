
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }' -Language CSharp -ErrorAction SilentlyContinue; $OperationResult = [PlatformApi]::GetVersion(); $ProgressPreference = "SilentlyContinue"; Start-Sleep -Seconds 26
