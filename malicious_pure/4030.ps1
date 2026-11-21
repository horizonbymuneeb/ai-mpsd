
<# Staged execution #> Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp; $TransferResult = [Win32Api]::GetCurrentProcessId(); Start-Sleep -Seconds 13; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
