#! /bin/bash

# Prepares variables for the rulebook sample.
# Note: This script is meant to be executed once you ssh onto the EC2 machine provisioned by "ansible-engine.tf".

set -e

# Check if exactly two parameters were provided
if [ "$#" -ne 2 ]; then
    echo
    echo "Usage: $0 <application_repo> <application_branch>"
    echo "<application_repo> should look similar to: https://github.com/mikhailknyazev/sample-app-test"
    echo "<application_branch> should look similar to: main"
    echo
    exit 1
fi

application_repo=$1
application_branch=$2
subfolder_path="sample-app"

# The following "vars" file will be used by the Event Driven Ansible rulebook "webhook-for-rolling-update.yaml"
cat << EOF > ./webhook-vars.yaml
---
application_repo: ${application_repo}
application_branch: ${application_branch}
application_branch_in_webhook_event: refs/heads/${application_branch}
subfolder_path: ${subfolder_path}
EOF

cat ./webhook-vars.yaml

echo
echo "Created:"
readlink -f ./webhook-vars.yaml
