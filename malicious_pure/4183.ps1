
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp
$ResultObject = [PlatformApi]::GetCurrentThreadId()
$StageMarker = "stage-3"
$Host.UI.RawUI.WindowTitle = "Windows Update"
