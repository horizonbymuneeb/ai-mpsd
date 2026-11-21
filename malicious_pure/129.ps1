
<# Host profiling #> Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp -ErrorAction SilentlyContinue; $TransferResult = [NativeApi]::GetCurrentProcessId(); $Host.UI.RawUI.WindowTitle = "Windows Update"
