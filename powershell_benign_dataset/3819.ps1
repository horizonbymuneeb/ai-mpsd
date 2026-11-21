#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$script:DefaultTimeout = 60
$script:ModuleVersion = '2.4.7'

function Get-ContosoService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoService
