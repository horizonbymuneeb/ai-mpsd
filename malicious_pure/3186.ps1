
# Payload transfer
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp
$TransferResult = [PlatformApi]::GetTickCount()
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
