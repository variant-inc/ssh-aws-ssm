######## Source ################################################################
# Open SSH Connection
#   ssh <INSTANCE_USER>@<INSTANCE_ID>:<AWS_PROFILE>
################################################################################
$ErrorActionPreference = "stop"

$AWS_PROFILE_SEPARATOR = ':'

$ec2_instance_id = "$($args[0])"
$ssh_user = "$($args[1])"
$ssh_port = "$($args[2])"
$ssh_public_key_path = "$($args[3])"
$ssh_public_key = "$(Get-Content "${ssh_public_key_path}")" -replace '\\', '\\'

if ($ec2_instance_id -match $AWS_PROFILE_SEPARATOR)
{
  $env:AWS_PROFILE = $ec2_instance_id.Split($AWS_PROFILE_SEPARATOR)[1]
  $ec2_instance_id = $ec2_instance_id.Split($AWS_PROFILE_SEPARATOR)[0]
}


$ssm_command = @"
{
  "Parameters": {
    "commands": [
      "mkdir -p /home/${ssh_user}/.ssh",
      "cd /home/${ssh_user}/.ssh || exit 1",
      "authorized_key='${ssh_public_key} ssm-session'",
      "echo `$authorized_key >> authorized_keys",
      "sleep 24h",
      "grep -v -F `$authorized_key authorized_keys > .authorized_keys",
      "mv .authorized_keys authorized_keys"
    ]
  }
}
"@

Set-Content -Path "$HOME/.ssh/command.json" -Value $ssm_command

Write-Host "Add public key ${ssh_public_key_path} to instance ${ec2_instance_id} for 24 hours"
aws ssm send-command `
  --instance-ids "${ec2_instance_id}" `
  --document-name 'AWS-RunShellScript' `
  --comment "Add an SSH public key to authorized_keys for 24 hours" `
  --cli-input-json file://$HOME/.ssh/command.json

Write-Host "Start ssm session to instance ${ec2_instance_id}"
aws ssm start-session `
  --target "${ec2_instance_id}" `
  --document-name 'AWS-StartSSHSession' `
  --parameters "portNumber=${ssh_port}"
