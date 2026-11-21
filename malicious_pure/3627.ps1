
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentThreadId(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $TransferResult = [NativeApi]::GetCurrentThreadId(); $ProgressPreference = "SilentlyContinue"
