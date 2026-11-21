
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp; $TransferResult = [PlatformApi]::GetTickCount(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Write-Verbose "stage marker 34 reached"
