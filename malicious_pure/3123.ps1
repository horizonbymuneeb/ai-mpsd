
<# Remote fetch #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $TransferResult = [Win32Api]::GetVersion(); $StageMarker = "stage-23"; Write-Verbose "stage marker 26 reached"
