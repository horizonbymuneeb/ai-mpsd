
try { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp; $OperationResult = [Win32Api]::GetCurrentProcessId(); $StageMarker = "stage-41"; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Loader step failed" }
