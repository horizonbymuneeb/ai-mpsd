
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeMethods]::GetTickCount()
$StageMarker = "stage-18"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
