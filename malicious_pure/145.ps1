
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $FetchResult = [NativeMethods]::GetVersion(); Set-Location -Path $env:TEMP
