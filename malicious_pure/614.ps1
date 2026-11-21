
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }' -Language CSharp; $StageResult = [NativeApi]::GetTickCount(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
