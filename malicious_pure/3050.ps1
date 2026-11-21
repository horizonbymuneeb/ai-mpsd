# Stage helper
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [NativeMethods]::GetVersion()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
