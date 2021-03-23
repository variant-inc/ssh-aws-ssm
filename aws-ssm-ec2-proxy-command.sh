#!/bin/sh
######## Source ################################################################
# Open SSH Connection
#   ssh <INSTANCE_USER>@<INSTANCE_ID>:<AWS_PROFILE>
################################################################################
set -exu

AWS_PROFILE_SEPARATOR='__'

ec2_instance_id="$1"
ssh_user="$2"
ssh_port="$3"
ssh_public_key_path="$4"
ssh_public_key="$(cat "${ssh_public_key_path}")"

if echo "${ec2_instance_id}" | grep -qe "${AWS_PROFILE_SEPARATOR}"; then
  aws_profile="${ec2_instance_id##*${AWS_PROFILE_SEPARATOR}}"
  ec2_instance_id="${ec2_instance_id%%${AWS_PROFILE_SEPARATOR}*}"
fi

aws sts get-caller-identity --profile "$aws_profile" || aws sso login --profile "$aws_profile"

echo >/dev/stderr "Add public key ${ssh_public_key_path} to instance ${ec2_instance_id} for 24 hours"
aws ssm send-command \
  --instance-ids "${ec2_instance_id}" \
  --document-name 'AWS-RunShellScript' \
  --comment "Add an SSH public key to authorized_keys for 24 hours" \
  --profile "$aws_profile" \
  --parameters commands="\"
    set -ex
    cd /home/${ssh_user}/.ssh || exit 1
    touch authorized_keys
    authorized_key='${ssh_public_key} ssm-session'
    grep -v -F \\\"\${authorized_key}\\\" authorized_keys > .authorized_keys || true
    mv .authorized_keys authorized_keys || true
    printf '%s' \\\"\${authorized_key}\\\" >> authorized_keys
  \"" || true

echo >/dev/stderr "Start ssm session to instance ${ec2_instance_id}"
aws ssm start-session \
  --target "${ec2_instance_id}" \
  --document-name 'AWS-StartSSHSession' \
  --parameters "portNumber=${ssh_port}" \
  --profile "$aws_profile"
