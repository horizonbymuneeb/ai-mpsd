$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [NativeApi]::GetCurrentThreadId()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
