
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetVersion(); }' -Language CSharp
$OperationResult = [NativeApi]::GetVersion()
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"
