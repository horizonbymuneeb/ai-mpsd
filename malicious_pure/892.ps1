
<# Staged execution #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }' -Language CSharp; $StageResult = [NativeApi]::GetVersion(); Start-Sleep -Seconds 12; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
