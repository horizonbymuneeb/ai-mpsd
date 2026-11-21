
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }" -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [PlatformApi]::GetCurrentThreadId(); $ProgressPreference = "SilentlyContinue"
