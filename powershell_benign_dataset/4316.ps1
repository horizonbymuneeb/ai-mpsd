#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$script:DefaultTimeout = 30
$script:ModuleVersion = '1.5.3'

function Get-ContosoService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}
Export-ModuleMember -Function Get-ContosoService
