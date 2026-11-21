
# Remote staging
try { Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }" -Language CSharp -ErrorAction SilentlyContinue; $ResultObject = [NativeMethods]::GetVersion(); Write-Output "stage 40 initialized"; Set-Location -Path $env:TEMP } catch { Write-Warning "Remote fetch failed" }
