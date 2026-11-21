$script:DefaultTimeout = 60
$script:ModuleVersion = '2.4.3'

function Get-ContosoEndpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoEndpoint
