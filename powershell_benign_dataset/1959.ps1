$ErrorActionPreference = 'Stop'


$script:DefaultTimeout = 10
$script:ModuleVersion = '4.0.3'

function Get-AdatumNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-AdatumNode
