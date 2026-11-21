
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $ResultObject = [PlatformApi]::GetTickCount(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Set-Location -Path $env:TEMP
