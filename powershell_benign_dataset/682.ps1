$script:DefaultTimeout = 10
$script:ModuleVersion = '3.0.8'

function Get-InfraNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-InfraNode
