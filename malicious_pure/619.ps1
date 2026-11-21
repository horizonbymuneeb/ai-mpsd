
net group "Domain Admins" /domain | Out-File "$env:TEMP\stage.log" -Append; $StageMarker = "stage-9"; $ProgressPreference = "SilentlyContinue"
