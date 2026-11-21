
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [PlatformApi]::GetCurrentProcessId()
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
