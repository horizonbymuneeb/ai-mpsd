#Requires -Version 5.1
$ErrorActionPreference = 'Stop'


$script:DefaultTimeout = 60
$script:ModuleVersion = '4.8.2'

function Get-ContosoInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoInventory
