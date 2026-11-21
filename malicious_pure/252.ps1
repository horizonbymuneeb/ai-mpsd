
<# Payload staging #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp; $StageResult = [NativeMethods]::GetCurrentThreadId(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $StageMarker = "stage-21"
