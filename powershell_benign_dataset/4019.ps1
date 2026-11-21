
$ErrorActionPreference = "Stop"



$script:DefaultTimeout = 30
$script:ModuleVersion = '3.8.6'

function Get-ContosoService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoService
