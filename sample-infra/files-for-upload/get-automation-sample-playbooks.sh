#! /bin/bash

# Retrieves the sample Ansible playbooks and rulebooks.
# Note: This script is meant to be executed once you ssh onto the EC2 machine provisioned by "ansible-engine.tf".

set -xe

git clone --depth 1 --branch main https://github.com/mikhailknyazev/automation-samples.git automation-samples && {
  sleep 1
  rm -rf roles
  mv -f automation-samples/sample-playbooks/* .
  rm -rf automation-samples/
}
