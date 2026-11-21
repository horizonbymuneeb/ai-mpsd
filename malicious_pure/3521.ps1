
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }" -Language CSharp
$OperationResult = [PlatformApi]::GetCurrentThreadId()
$StageMarker = "stage-44"
