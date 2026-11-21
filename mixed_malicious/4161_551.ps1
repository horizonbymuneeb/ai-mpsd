
<# Stage transfer #> $NativeCode = "using System; using System.Runtime.InteropServices; public static class Win32Api { [DllImport(`"kernel32.dll`")] public static extern uint GetVersion(); }"; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $FetchResult = [Win32Api]::GetVersion(); Write-Output "stage 28 initialized"; $ProgressPreference = "SilentlyContinue"
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$script:DefaultTimeout = 10
$script:ModuleVersion = '2.4.0'

function Get-InfraNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-InfraNode
