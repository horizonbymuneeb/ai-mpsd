# Payload transfer
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$OperationResult = [NativeMethods]::GetTickCount()
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
