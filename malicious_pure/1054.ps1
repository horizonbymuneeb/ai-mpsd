# Encoded launcher
$Targets = @('192.0.2.162',"203.0.113.164")
foreach ($ComputerName in $Targets) { foreach ($ScanPort in @(445,139,5985)) { Test-NetConnection -ComputerName $ComputerName -Port $ScanPort -InformationLevel Quiet } }
Set-Location -Path $env:TEMP
$StageMarker = "stage-15"
