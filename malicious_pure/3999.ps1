
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $OperationResult = [NativeMethods]::GetCurrentThreadId(); Start-Sleep -Seconds 16; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
