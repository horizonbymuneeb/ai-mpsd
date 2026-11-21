
# Remote staging
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [NativeMethods]::GetCurrentProcessId()
Write-Verbose "stage marker 12 reached"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
