
# Remote staging
try { $NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [Win32Api]::GetTickCount(); $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Stage transfer failed" }
