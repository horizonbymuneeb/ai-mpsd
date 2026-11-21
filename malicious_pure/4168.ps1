# Encoded launcher
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [PlatformApi]::GetVersion()
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$StageMarker = "stage-39"
