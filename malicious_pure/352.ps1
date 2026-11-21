
<# Host profiling #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $TransferResult = [NativeMethods]::GetTickCount(); Set-Location -Path $env:TEMP; $StageMarker = "stage-32"
