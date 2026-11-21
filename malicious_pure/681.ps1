Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetTickCount(); }" -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [NativeMethods]::GetTickCount()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
