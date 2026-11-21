$script:DefaultTimeout = 10
$script:ModuleVersion = '1.4.2'

function Get-ContosoInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoInventory
