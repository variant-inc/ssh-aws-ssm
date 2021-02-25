######## Source ################################################################
# Open SSH Connection
#   ssh <INSTANCE_USER>@<INSTANCE_ID>:<AWS_PROFILE>
################################################################################
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap
{
  Write-Error $_ -ErrorAction Continue
  exit 1
}
function CommandAliasFunction
{
  Write-Information ""
  Write-Information "$args"
  $cmd, $args = $args
  & "$cmd" $args
  if ($LASTEXITCODE)
  {
    throw "Exception Occured"
  }
  Write-Information ""
}

Set-Alias -Name ce -Value CommandAliasFunction -Scope script

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

Write-Host ${ssh_public_key}

$commands = @"
set -ex
cd /home/${ssh_user}/.ssh || exit 1
touch authorized_keys
authorized_key='${ssh_public_key} ssm-session'
grep -v -F \"`$authorized_key\" authorized_keys > .authorized_keys || true
mv .authorized_keys authorized_keys || true
printf '%s' \"`$authorized_key\" >> authorized_keys
"@.replace("`n", "\n")


$ssm_command = @"
{
  "Parameters": {
    "commands": ["$commands"]
  }
}
"@

Set-Content -Path "$HOME/.ssh/command.json" -Value $ssm_command

Write-Host "Add public key ${ssh_public_key_path} to instance ${ec2_instance_id} for 24 hours"
aws ssm send-command `
  --instance-ids "${ec2_instance_id}" `
  --document-name 'AWS-RunShellScript' `
  --comment "Add an SSH public key to authorized_keys for 24 hours" `
  --cli-input-json file://$HOME/.ssh/command.json `
  --max-errors 1 `
  --cloud-watch-output-config CloudWatchOutputEnabled=true

# Remove-Item "$HOME/.ssh/command.json"

Write-Host "Start ssm session to instance ${ec2_instance_id}"
ce aws ssm start-session `
  --target "${ec2_instance_id}" `
  --document-name 'AWS-StartSSHSession' `
  --parameters "portNumber=${ssh_port}"
