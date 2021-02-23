#!/bin/bash

set -ex

if ! command -v aws &>/dev/null; then
  unameOut="$(uname -s)"
  if [ "$unameOut" == "Linux" ] || [ "$unameOut" == "CYGWIN" ] || [ "$unameOut" == "MINGW" ]; then
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm awscliv2.zip
    rm -rf ./aws
  elif [ "$unameOut" == "Darwin" ]; then
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg AWSCLIV2.pkg -target /
    rm AWSCLIV2.pkg
  fi
  aws --version
fi

if ! command -v session-manager-plugin &>/dev/null; then
  unameOut="$(uname -s)"
  if [ "$unameOut" == "Linux" ] || [ "$unameOut" == "CYGWIN" ] || [ "$unameOut" == "MINGW" ]; then
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    sudo dpkg -i session-manager-plugin.deb
    rm session-manager-plugin.deb
  elif [ "$unameOut" == "Darwin" ]; then
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
    unzip sessionmanager-bundle.zip
    sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
    rm sessionmanager-bundle.zip
  fi
  session-manager-plugin
fi

mkdir -p "$HOME/.ssh"
cp aws-ssm-ec2-proxy-command.sh "$HOME/.ssh/aws-ssm-ec2-proxy-command.sh"
chmod +x "$HOME/.ssh/aws-ssm-ec2-proxy-command.sh"

if [[ $(grep -q 'host i-*' "$HOME/.ssh/config") != 0 ]]; then
  cat <<EOF >>~/.ssh/config
host i-* mi-*
  IdentityFile ~/.ssh/id_rsa
  ProxyCommand ~/.ssh/aws-ssm-ec2-proxy-command.sh %h %r %p ~/.ssh/id_rsa.pub
  StrictHostKeyChecking no
EOF
fi
