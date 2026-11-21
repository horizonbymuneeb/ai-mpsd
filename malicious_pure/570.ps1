
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $ResultObject = [PlatformApi]::GetCurrentProcessId(); Start-Sleep -Seconds 42; Set-Location -Path $env:TEMP
