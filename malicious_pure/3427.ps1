
$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjphZmM0cnEwZDA3'); $OperationResult = [Reflection.Assembly]::Load($ManagedBytes); $OperationResult.GetTypes().Count; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $StageMarker = "stage-41"
