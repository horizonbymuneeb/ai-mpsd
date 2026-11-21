
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeMethods]::GetCurrentThreadId()
Write-Verbose "stage marker 37 reached"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
