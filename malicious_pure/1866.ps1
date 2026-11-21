
<# Stage transfer #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp; $ResultObject = [NativeMethods]::GetCurrentProcessId(); $Host.UI.RawUI.WindowTitle = "Windows Update"
