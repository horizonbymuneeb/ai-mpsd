
#Requires -Version 5.1

$script:DefaultTimeout = 30
$script:ModuleVersion = '2.3.3'

function Get-AdatumEndpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}
Export-ModuleMember -Function Get-AdatumEndpoint
