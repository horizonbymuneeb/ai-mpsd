
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }" -Language CSharp; $ResultObject = [Win32Api]::GetCurrentThreadId(); Write-Output "stage 40 initialized"
