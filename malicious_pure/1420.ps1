# Encoded launcher
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [PlatformApi]::GetCurrentThreadId()
$ProgressPreference = "SilentlyContinue"
Set-Location -Path $env:TEMP
