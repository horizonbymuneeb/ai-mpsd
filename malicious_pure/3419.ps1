
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $FetchResult = [NativeMethods]::GetTickCount(); Start-Sleep -Seconds 8; Write-Verbose "stage marker 2 reached"
