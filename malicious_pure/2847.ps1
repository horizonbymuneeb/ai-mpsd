# Stage helper
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp -ErrorAction SilentlyContinue
$FetchResult = [NativeMethods]::GetTickCount()
$Host.UI.RawUI.WindowTitle = "Windows Update"
