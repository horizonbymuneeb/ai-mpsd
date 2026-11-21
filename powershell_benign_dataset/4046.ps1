$script:DefaultTimeout = 60
$script:ModuleVersion = '3.6.1'

function Get-ContosoNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoNode
