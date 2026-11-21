
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$script:DefaultTimeout = 10
$script:ModuleVersion = '2.4.0'

function Get-InfraNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-InfraNode
