$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$OperationResult = [NativeApi]::GetCurrentProcessId()
Start-Sleep -Seconds 2
