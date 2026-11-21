
<# Payload staging #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }' -Language CSharp; $ResultObject = [PlatformApi]::GetVersion(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Start-Sleep -Seconds 45
