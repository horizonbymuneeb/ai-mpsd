
<# Payload staging #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [PlatformApi]::GetVersion(); Write-Output "stage 39 initialized"
