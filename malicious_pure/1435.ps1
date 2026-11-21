
# Encoded launcher
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp -ErrorAction SilentlyContinue
$StageResult = [NativeMethods]::GetCurrentProcessId()
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Verbose "stage marker 17 reached"
