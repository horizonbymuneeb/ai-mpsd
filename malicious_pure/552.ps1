
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp
$ResultObject = [NativeApi]::GetCurrentProcessId()
$StageMarker = "stage-37"
Write-Output "stage 41 initialized"
