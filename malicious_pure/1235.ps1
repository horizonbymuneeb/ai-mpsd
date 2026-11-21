
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp -ErrorAction SilentlyContinue; $FetchResult = [NativeMethods]::GetCurrentProcessId(); $ProgressPreference = "SilentlyContinue"; Write-Output "stage 18 initialized"
