# Encoded launcher
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }" -Language CSharp
$StageResult = [Win32Api]::GetCurrentThreadId()
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
