
<# Payload staging #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [Win32Api]::GetCurrentProcessId(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
