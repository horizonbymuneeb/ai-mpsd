
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp; $TransferResult = [NativeApi]::GetCurrentThreadId(); $ProgressPreference = "SilentlyContinue"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
