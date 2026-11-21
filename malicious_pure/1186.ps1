
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp
$TransferResult = [NativeApi]::GetCurrentThreadId()
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
