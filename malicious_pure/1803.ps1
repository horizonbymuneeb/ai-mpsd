
# Encoded launcher
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }" -Language CSharp
$OperationResult = [NativeApi]::GetCurrentThreadId()
Write-Output "stage 27 initialized"
