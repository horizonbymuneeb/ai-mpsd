#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$script:DefaultTimeout = 10
$script:ModuleVersion = '2.3.0'

function Get-InfraInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-InfraInventory
