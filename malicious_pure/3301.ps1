
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [Win32Api]::GetCurrentProcessId(); Start-Sleep -Seconds 32; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
