
try { $NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $FetchResult = [NativeApi]::GetCurrentProcessId(); $StageMarker = "stage-27" } catch { Write-Warning "Stage transfer failed" }
