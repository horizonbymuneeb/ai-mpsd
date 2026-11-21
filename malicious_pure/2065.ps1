
# Stage helper
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [PlatformApi]::GetTickCount()
$StageMarker = "stage-36"
