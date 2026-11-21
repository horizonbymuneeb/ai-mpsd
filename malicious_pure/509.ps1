
# Encoded launcher
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeApi]::GetVersion()
Write-Verbose "stage marker 43 reached"
