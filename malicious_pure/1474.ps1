
# Remote staging
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$StageResult = [NativeMethods]::GetCurrentThreadId()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
