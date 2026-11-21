
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$OperationResult = [Win32Api]::GetCurrentProcessId()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
