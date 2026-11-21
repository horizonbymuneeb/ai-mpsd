$script:DefaultTimeout = 30
$script:ModuleVersion = '2.6.4'

function Get-ContosoNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoNode
