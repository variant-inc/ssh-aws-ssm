# SSH Using SSM

## Installation

Run either [install.ps1](install.ps1) or [install.sh](install.sh). Depending on the OS Model, it will run separate commands

Verify that it was successful by checking `$HOME/.ssh/config` file. You'll find some host like below

```text
host i-* mi-*
  IdentityFile ~/.ssh/id_rsa
  ProxyCommand ~/.ssh/aws-ssm-ec2-proxy-command.sh %h %r %p ~/.ssh/id_rsa.pub
  StrictHostKeyChecking no
```

## Usage

Run `ssh-keygen` the very first time if there is no `id_rsa` in your `$HOME/.ssh`

### Using SSH

1. Get the credentials from AWS using `aws configure SSO` command. Note down the profile at the very end.
2. Run SSH in terminal using the following syntax \
    `ssh <user>@<instance:id>:<aws-profile>` \
  For example: \
    `ssh ubuntu@i-12312hbu1:AWSAdministrator-423213`

### Using VSCode

1. Add a host to `$HOME/.ssh/config` with the following syntax

  ```text
  host <instance:id>:<aws-profile>
  User <user>
  ```

  For example:

  ```text
  host i-083d48d20995d057c:AWSAdministratorAccess-663374859601
  User ubuntu
  ```

2. Install `Remote - SSH` extension in vscode
3. Open Remote Window
4. Select `Remote-SSH: Connect to Host...`
5. Select the host that you just added and you are good to go

## Support

If you have any issues or need assistance, please contact [#devops](https://usxventures.slack.com/archives/CQD742SSG)
