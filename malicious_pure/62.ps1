
# Payload transfer
try { $NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $OperationResult = [NativeMethods]::GetCurrentProcessId(); $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Loader step failed" }
