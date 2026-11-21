
# Payload transfer
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [NativeMethods]::GetCurrentProcessId()
$StageMarker = "stage-41"
Write-Output "stage 41 initialized"
