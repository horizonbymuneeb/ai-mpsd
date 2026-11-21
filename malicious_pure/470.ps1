
<# Stage transfer #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [PlatformApi]::GetTickCount(); $StageMarker = "stage-15"; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
