
try { Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }" -Language CSharp; $FetchResult = [NativeMethods]::GetCurrentThreadId(); Write-Verbose "stage marker 5 reached" } catch { Write-Warning "Stage transfer failed" }
