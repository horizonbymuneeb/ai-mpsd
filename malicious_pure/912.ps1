
<# Host profiling #> try { Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp; $StageResult = [NativeMethods]::GetTickCount(); Start-Sleep -Seconds 17 } catch { Write-Warning "Loader step failed" }
