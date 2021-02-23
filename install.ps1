$ErrorActionPreference = "stop"

try
{
  aws --version
}
catch
{
  if ($PSVersionTable.OS -match "Windows")
  {
    Start-Process "https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html"
  }
  elseif ($PSVersionTable.OS -match "Linux")
  {
    Invoke-WebRequest "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    Remove-Item awscliv2.zip
    Remove-Item aws -Force -Recurse
  }
  elseif ($PSVersionTable.OS -match "Darwin")
  {
    Invoke-WebRequest "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg AWSCLIV2.pkg -target /
    Remove-Item AWSCLIV2.pkg
  }
  aws --version
}

try
{
  session-manager-plugin
}
catch
{
  if ($PSVersionTable.OS -match "Windows")
  {
    Start-Process "https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows"
  }
  elseif ($PSVersionTable.OS -match "Linux")
  {
    Invoke-WebRequest "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    sudo dpkg -i session-manager-plugin.deb
    Remove-Item session-manager-plugin.deb
  }
  elseif ($PSVersionTable.OS -match "Darwin")
  {
    Invoke-WebRequest "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
    unzip sessionmanager-bundle.zip
    sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
    Remove-Item sessionmanager-bundle.zip
  }
  session-manager-plugin
}

New-Item -ItemType Directory -Force -Path "$HOME/.ssh"
Copy-Item aws-ssm-ec2-proxy-command.sh "$HOME/.ssh/aws-ssm-ec2-proxy-command.ps1"
chmod +x "$HOME/.ssh/aws-ssm-ec2-proxy-command.ps1"

if (!(Test-Path "$HOME/.ssh/config"))
{
  New-Item -Path $HOME/.ssh/config
  Write-Host "Created new file $HOME/.ssh/config"
}

if (! $(Get-Content "$HOME/.ssh/config") -match "host i-* mi-*")
{
  if ($PSVersionTable.OS -match "Windows")
  {
    $pwsh = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
  }
  elseif ($PSVersionTable.OS -match "Linux" -or $PSVersionTable.OS -match "Darwin")
  {
    $pwsh = $(which pwsh)
  }
  $text = @"

host i-* mi-*
  IdentityFile $HOME/.ssh/id_rsa
  ProxyCommand $pwsh "$HOME/.ssh/aws-ssm-ec2-proxy-command.ps1 %h %r %p $HOME/.ssh/id_rsa.pub"
  StrictHostKeyChecking no
"@
  Add-Content -Path "$HOME/.ssh/config" -Value $text
  Write-Host "Added ssh config"
}
Write-Host "Use command: ssh user@instance-id:aws-profile"
