
<# Remote fetch #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }' -Language CSharp; $FetchResult = [Win32Api]::GetVersion(); $Host.UI.RawUI.WindowTitle = "Windows Update"
