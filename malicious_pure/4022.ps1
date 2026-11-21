
<# Remote fetch #> $NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [NativeMethods]::GetVersion(); Write-Verbose "stage marker 43 reached"; Start-Sleep -Seconds 34
