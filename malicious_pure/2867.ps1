
<# Staged execution #> Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp; $StageResult = [Win32Api]::GetTickCount(); Set-Location -Path $env:TEMP
