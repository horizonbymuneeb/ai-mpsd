
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }" -Language CSharp; $TransferResult = [NativeApi]::GetVersion(); Remove-Item -Path "$env:TEMP\stage2.bin" -Force
