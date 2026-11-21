
<# Host profiling #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp -ErrorAction SilentlyContinue; $FetchResult = [NativeApi]::GetCurrentProcessId(); Set-Location -Path $env:TEMP
