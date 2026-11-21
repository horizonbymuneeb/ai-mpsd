# Stage helper
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeMethods]::GetVersion()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
