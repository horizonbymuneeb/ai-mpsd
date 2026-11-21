$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [NativeMethods]::GetTickCount()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
