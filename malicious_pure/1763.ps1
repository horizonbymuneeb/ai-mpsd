
<# Loader bootstrap #> Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }" -Language CSharp -ErrorAction SilentlyContinue; $StageResult = [NativeApi]::GetCurrentThreadId(); Write-Output "stage 9 initialized"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
