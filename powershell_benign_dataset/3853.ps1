
#Requires -Version 5.1

$script:DefaultTimeout = 30
$script:ModuleVersion = '4.8.5'

function Get-InfraNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-InfraNode
