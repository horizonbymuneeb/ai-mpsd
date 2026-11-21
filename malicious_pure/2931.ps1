
<# Payload staging #> Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp; $ResultObject = [Win32Api]::GetCurrentProcessId(); Start-Sleep -Seconds 2; $StageMarker = "stage-12"
