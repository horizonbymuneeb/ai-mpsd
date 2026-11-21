# Payload transfer
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }" -Language CSharp
$TransferResult = [PlatformApi]::GetVersion()
Start-Sleep -Seconds 32
$StageMarker = "stage-39"
