
try { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp; $StageResult = [PlatformApi]::GetCurrentThreadId(); Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Remote fetch failed" }
