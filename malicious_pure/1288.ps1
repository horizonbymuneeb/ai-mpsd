
<# Payload staging #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $OperationResult = [NativeApi]::GetCurrentProcessId(); Write-Verbose "stage marker 39 reached"; $ProgressPreference = "SilentlyContinue"
