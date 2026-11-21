
# Stage helper
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$StageResult = [NativeApi]::GetCurrentThreadId()
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Output "stage 36 initialized"
