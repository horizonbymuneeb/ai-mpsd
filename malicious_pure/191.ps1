
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }' -Language CSharp; $ResultObject = [Win32Api]::GetTickCount(); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
