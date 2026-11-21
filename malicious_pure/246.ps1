
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }" -Language CSharp; $FetchResult = [NativeMethods]::GetCurrentThreadId(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Output "stage 10 initialized"
