
<# Host profiling #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $OperationResult = [NativeApi]::GetVersion(); $Host.UI.RawUI.WindowTitle = "Windows Update"; Write-Output "stage 41 initialized"
