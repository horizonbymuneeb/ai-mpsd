
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp -ErrorAction SilentlyContinue; $TransferResult = [Win32Api]::GetTickCount(); Write-Verbose "stage marker 33 reached"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
