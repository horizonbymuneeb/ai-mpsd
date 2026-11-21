
<# Payload staging #> Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }" -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [NativeMethods]::GetVersion(); Write-Output "stage 21 initialized"; $StageMarker = "stage-44"
