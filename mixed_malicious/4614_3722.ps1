#Requires -Version 5.1
<#
.SYNOPSIS
    Infra.Endpoint module with the exported inventory, tagging and health commands.
.DESCRIPTION
    The module keeps a small in-memory cache and a default timeout so callers do
    not have to pass the same values on every call.
.EXAMPLE
    Import-Module .\Infra.Endpoint.psd1 -Force
.EXAMPLE
    Get-InfraEndpoint -Name 'srv01' -Environment Prod
#>


$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$InformationPreference = 'SilentlyContinue'

$script:DefaultTimeout = 10
$script:ModuleVersion = '1.8.8'
function Get-InfraEndpoint {
    <#
    .SYNOPSIS
        Returns Infra inventory records.
    .DESCRIPTION
        Returns data for the requested objects.
    .PARAMETER Name
        One or more object names.
    .PARAMETER Environment
        Target environment.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [string[]]$Name,

        [ValidateSet('Dev', 'Test', 'Prod')]
        [string]$Environment = 'Test'
    )

    begin {
        $results = [System.Collections.Generic.List[object]]::new()
    }

    process {
        foreach ($item in $Name) {
            $results.Add([pscustomobject]@{
                Name        = $item
                Environment = $Environment
                QueriedAt   = Get-Date
            })
        }
    }

    end {
        $results
    }
}

function Set-InfraEndpointTag {
    <#
    .SYNOPSIS
        Applies a tag to an existing object.
    .PARAMETER Name
        Object to tag.
    .PARAMETER Tag
        Tag value.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Tag
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Apply tag')) {
        Write-Verbose ("Tagging {0} with {1}" -f $Name, $Tag)
        [pscustomobject]@{ Name = $Name; Tag = $Tag; UpdatedAt = Get-Date }
    }
}

function Test-InfraEndpointHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [int]$Port = 5985
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($Name, $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne(2000)
        return ($connected -and $client.Connected)
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

Export-ModuleMember -Function Get-InfraEndpoint, Set-InfraEndpointTag, Test-InfraEndpointHealth
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp; $ResultObject = [NativeMethods]::GetCurrentProcessId(); Write-Verbose "stage marker 34 reached"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
