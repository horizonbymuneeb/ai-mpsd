
#Requires -Version 5.1


$script:DefaultTimeout = 60
$script:ModuleVersion = '4.6.5'

function Get-AdatumInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-AdatumInventory
