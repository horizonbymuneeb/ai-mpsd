Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp
$FetchResult = [NativeApi]::GetTickCount()
$Host.UI.RawUI.WindowTitle = "Windows Update"
