
# Stage helper
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$OperationResult = [PlatformApi]::GetTickCount()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Output "stage 12 initialized"
