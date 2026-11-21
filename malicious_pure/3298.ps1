# Remote staging
$NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [Win32Api]::GetTickCount()
Write-Verbose "stage marker 35 reached"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
