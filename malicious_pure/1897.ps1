Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }' -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [PlatformApi]::GetTickCount()
$ProgressPreference = "SilentlyContinue"
