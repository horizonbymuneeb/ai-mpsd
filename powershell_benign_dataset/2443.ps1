$script:DefaultTimeout = 30
$script:ModuleVersion = '2.8.4'
function Get-AdatumInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-AdatumInventory
