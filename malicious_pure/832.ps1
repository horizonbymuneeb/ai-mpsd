
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp; $FetchResult = [NativeMethods]::GetCurrentProcessId(); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
