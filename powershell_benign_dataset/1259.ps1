
#Requires -Version 5.1

$script:DefaultTimeout = 10
$script:ModuleVersion = '4.4.0'
function Get-ContosoNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoNode
