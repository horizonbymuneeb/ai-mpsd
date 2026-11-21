$NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [Win32Api]::GetVersion()
Start-Sleep -Seconds 2
$Host.UI.RawUI.WindowTitle = "Windows Update"
