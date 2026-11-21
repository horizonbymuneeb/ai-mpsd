# Payload transfer
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeApi]::GetTickCount()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
