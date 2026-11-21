
<# Staged execution #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $StageResult = [PlatformApi]::GetCurrentThreadId(); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
