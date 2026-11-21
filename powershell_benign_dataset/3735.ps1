
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$script:DefaultTimeout = 30
$script:ModuleVersion = '4.3.9'

function Get-ContosoService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoService
