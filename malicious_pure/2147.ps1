
$NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [Win32Api]::GetTickCount(); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
