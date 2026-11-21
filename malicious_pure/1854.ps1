
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }" -Language CSharp; $StageResult = [Win32Api]::GetVersion(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
