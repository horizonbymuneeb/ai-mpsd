
# Payload transfer
try { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp; $OperationResult = [NativeMethods]::GetCurrentProcessId(); $Host.UI.RawUI.WindowTitle = "Windows Update"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Stage transfer failed" }
