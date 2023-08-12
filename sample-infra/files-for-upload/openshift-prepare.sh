#! /bin/bash

# Prepares OpenShift client environment.
# Note: This script is meant to be executed once you ssh onto the EC2 machine provisioned by "ansible-engine.tf".

set -e

# Check if exactly two parameters were provided
if [ "$#" -ne 2 ]; then
    echo
    echo "Usage: $0 <openshift_host> <openshift_token>"
    echo "<openshift_host> should look similar to: sandbox-n3.k4ri.p2.openshiftapps.com"
    echo "<openshift_token> should look similar to: sha256~812G1w6UioKITX-95sV7vUoPptCasa0jjhsdjhdViQt"
    echo
    exit 1
fi

openshift_host=$1
openshift_token=$2

echo "OpenShift Host is: ${openshift_host}"
echo "OpenShift Token is: ${openshift_token:0:4}..."

curl -L -o oc.tar "https://downloads-openshift-console.apps.${openshift_host}/amd64/linux/oc.tar"
tar xvf oc.tar
rm oc.tar
sudo mv ./oc /usr/local/bin/
sudo chmod +x /usr/local/bin/oc
oc login --token="${openshift_token}" --server="https://api.${openshift_host}:6443"
oc version

# The following "vars" file will be used by Ansible playbooks
cat << EOF > ./openshift-vars.yaml
openshift:
  kubeconfig_file: $(readlink -f ~/.kube/config)
  namespace_name: $(oc project -q)
EOF

echo
echo "Created:"
readlink -f ./openshift-vars.yaml
