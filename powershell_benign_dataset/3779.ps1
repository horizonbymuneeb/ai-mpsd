
$script:DefaultTimeout = 60
$script:ModuleVersion = '4.9.9'

function Get-AdatumInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}
Export-ModuleMember -Function Get-AdatumInventory
