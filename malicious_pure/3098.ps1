
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp -ErrorAction SilentlyContinue
$FetchResult = [PlatformApi]::GetCurrentThreadId()
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
