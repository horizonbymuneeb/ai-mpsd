
$ErrorActionPreference = "Stop"



$script:DefaultTimeout = 30
$script:ModuleVersion = '4.5.7'

function Get-InfraInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-InfraInventory
