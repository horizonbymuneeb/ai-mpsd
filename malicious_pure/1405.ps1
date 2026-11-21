$NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [PlatformApi]::GetCurrentThreadId()
$ProgressPreference = "SilentlyContinue"
