
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }" -Language CSharp; $TransferResult = [PlatformApi]::GetVersion(); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
