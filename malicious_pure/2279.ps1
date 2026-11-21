# Encoded launcher
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeApi]::GetTickCount()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Verbose "stage marker 26 reached"
