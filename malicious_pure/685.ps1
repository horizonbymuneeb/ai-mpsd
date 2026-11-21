$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [NativeMethods]::GetCurrentThreadId()
$ProgressPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Windows Update"
