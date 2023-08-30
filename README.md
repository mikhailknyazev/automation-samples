
# Samples: Ansible, Event Driven Ansible, GitOps, Cloud (AWS), OpenShift, Terraform

Welcome! We start with [installation](#1-installation-of-the-sample-data-centre-in-aws) of the sample Data Centre of four Linux boxes in AWS, then [deploy the sample App](#2-deploy-the-sample-app) into it. After that, we [deploy](#3-deploy-the-haproxy-load-balancer-and-health-checker) the HAProxy load balancer into the Data Centre and the Health Checker component into a free "Developer Sandbox" OpenShift environment. We try a [simple rolling update of the App](#4-simple-rolling-update-of-the-app) behind the just deployed HAProxy. Then we go ahead and try [GitOps-style rolling update](#5-gitops-style-rolling-update-of-the-app-from-a-different-github-repository) of the App from a different GitHub repository, using Event Driven Ansible.

Please do not forget to remove all the compute resources after you finish experimenting in order to not incur too much AWS costs. In the end, we [demonstrate](#6-dangerous-zone---removal-of-the-sample-data-centre) how to drop the four "sample Data Centre" `t2.micro` EC2 instances efficiently.

**Read more in [Introduction](#introduction) below.**

[![automation-samples-preview.png](images%2Fautomation-samples-preview.png)](#introduction)

## Table of Contents

- [Disclaimer](#disclaimer)
- [Introduction](#introduction)
- [1. Installation of the sample Data Centre in AWS](#1-installation-of-the-sample-data-centre-in-aws)
    - [Step 1.1. Install Terraform](#step-11-install-terraform)
    - [Step 1.2. Clone this Repository from GitHub](#step-12-clone-this-repository-from-github)
    - [Step 1.3. Configure AWS Credentials](#step-13-configure-aws-credentials)
    - [Step 1.4. Create SSH Keys](#step-14-create-ssh-keys)
    - [Step 1.5. Create all](#step-15-create-all)
    - [Step 1.6. Verify all](#step-16-verify-all)
- [2. Deploy the sample App](#2-deploy-the-sample-app)
- [3. Deploy the HAProxy load balancer and Health Checker](#3-deploy-the-haproxy-load-balancer-and-health-checker)
    - [3.1. Developer Sandbox OpenShift environment](#31-developer-sandbox-openshift-environment)
    - [3.2. Deploy the components](#32-deploy-the-components)
- [4. Simple rolling update of the App](#4-simple-rolling-update-of-the-app)
- [5. GitOps-style rolling update of the App from a different GitHub repository](#5-gitops-style-rolling-update-of-the-app-from-a-different-github-repository)
    - [5.1. Prepare a different GitHub repository for sample App](#51-prepare-a-different-github-repository-for-sample-app)
    - [5.2. Run the components](#52-run-the-components)
- [6. Dangerous zone - removal of the sample Data Centre](#6-dangerous-zone---removal-of-the-sample-data-centre)

# Disclaimer

Automation samples in this personal repository are developed by Michael Knyazev (Mikhail Vladimirovich Kniazev) as a hobby personal project, using some resources originally built by Gineesh Madapparambath. The content is published under the standard MIT License; it uses a copy of Jeff Geerling's "haproxy" Ansible role released under MIT License as well. The effective disclaimers are as follows in summary:
* **Warranty Disclaimer**: The license disclaims any warranty and provides the "Software" "as is," without any warranty.
* **Liability Disclaimer**: The authors are not liable for anything related to this "Software".

[TOC](#table-of-contents)

# Introduction

The sample App is a simple Web application served by Apache HTTP Server on Linux boxes. The samples demonstrate how we can:
* Automate the App deployment process, keeping its service highly available:
  - Ansible-managed rolling updates
  - Multiple managed Apache Linux boxes
  - HAProxy-based load balancing
* Implement GitOps for the App using Event Driven Ansible
  - Increased App development productivity
  - Improved traceability of changes to Linux workloads
* Improve the App observability via a remote Health Checker component deployed in OpenShift
    - In-datacentre simple deployment of Express.js application using Source-to-Image (S2I) feature of OpenShift
    - Using a free "Developer Sandbox" OpenShift environment
* Deploy a sample Datacentre of Linux boxes on AWS cloud with Terraform-based provisioning and Ansible-based configuration 
* Automate updating installed Linux packages to their latest available versions

[TOC](#table-of-contents)

# 1. Installation of the sample Data Centre in AWS

## Step 1.1. Install Terraform

Download and Install Terraform on your local computer.

See also:
* https://developer.hashicorp.com/terraform/downloads
* https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

[TOC](#table-of-contents)

## Step 1.2. Clone this Repository from GitHub

```shell
$ git clone https://github.com/mikhailknyazev/automation-samples.git
# Cloning into 'automation-samples'...
# remote: Enumerating objects: 108, done.
# remote: Counting objects: 100% (108/108), done.
# remote: Compressing objects: 100% (79/79), done.
# remote: Total 108 (delta 23), reused 94 (delta 12), pack-reused 0
# Receiving objects: 100% (108/108), 78.28 KiB | 5.22 MiB/s, done.
# Resolving deltas: 100% (23/23), done.

$ ls
# automation-samples

$ cd automation-samples/
```

[TOC](#table-of-contents)

## Step 1.3. Configure AWS Credentials

Go to "AWS Console" –> "IAM" -> "Users" -> "Add User" and select "Programmatic access".
Grant the user the `AdministratorAccess` role.
>Important: Copy the "Access key ID" and "Secret access key" as we need this in next steps.

On your computer, add the new AWS Credentials as follows. If you have already configured other credentials, then add this as new profile -- `[automation-samples]` in the example below. Add your two values there correspondingly:
* "Access key ID"
* "Secret access key"

The file now can look as follows:

`$ cat ~/.aws/credentials`
```
[default]
aws_access_key_id=BUIA5WGDUFEXAMPLEKoP
aws_secret_access_key=ZI1v7OXMMYNRlNYXOI6YPxZEXAMPLEACCESSKEYX

[automation-samples]
aws_access_key_id=AKIA5WGDZFEXAMPLEKEY
aws_secret_access_key=Wb1v7OXMMYNRlNYXOGK5sPxZEXAMPLEACCESSKEY
```

Remember to use the correct profile name in your terraform file [variables.tf](./sample-infra/variables.tf). It is `automation-samples` in our case for variable `aws_profile`.

You might also wish to update the AWS Region to use for deployment. It is configured in the same file  [variables.tf](./sample-infra/variables.tf) (the `aws_region` variable), it defaults to `ap-southeast-2`.
Note: if you are changing the target AWS Region, then you will likely need to update the base `aws_ami_id`. Please see corresponding comments in file  [variables.tf](./sample-infra/variables.tf) for that variable.

[TOC](#table-of-contents)

## Step 1.4. Create SSH Keys

Create SSH Keys to access the AWS EC2 instances (virtual machines) of the  "sample Data Centre".

For example, you can run the following command:
```shell
ssh-keygen -t ed25519 -N '' -f ~/.ssh/automation-samples

# Generating public/private ed25519 key pair.
# Your identification has been saved in /Users/myusername/.ssh/automation-samples
# Your public key has been saved in /Users/myusername/.ssh/automation-samples.pub
```

Here's what each part of the command does:

`ssh-keygen`: This is the command-line utility for generating SSH key pairs.
* `-t ed25519`: Specifies the key type as Ed25519, which is a strong and modern elliptic curve algorithm.
* `-N ''`: Sets an empty passphrase for the private key, ensuring no passphrase is required when using the key.
* `-f ~/.ssh/automation-samples`: Specifies the file name and path for the generated key pair. In this case, the key pair will be saved as automation-samples in the `~/.ssh/` directory. 

After running this command, you will have two files in the `~/.ssh/` directory:

* `automation-samples`: This is the private key file. Keep this file secure and never share it with anyone.
* `automation-samples.pub`: This is the public key file. You can share this key with remote systems that you want to access using SSH. Our scripts will automatically install it into the "sample Data Centre" EC2 instances.

Remember to use the correct key names in your terraform file [variables.tf](./sample-infra/variables.tf). In our case, the values are:
* `~/.ssh/automation-samples` for variable `ssh_pair_private_key`
* `~/.ssh/automation-samples.pub` for variable `ssh_pair_public_key`

[TOC](#table-of-contents)

## Step 1.5. Create all

Create the sample Data Centre in AWS with Terraform and Ansible!

First, verify you are in the home folder of the repository in your CLI:
```shell
$ pwd
# /Users/myusername/.../automation-samples
```

Change directory as follows:
```shell
$ cd sample-infra/

$ pwd
# /Users/myusername/.../automation-samples/sample-infra
```

Init Terraform project for the folder:
```shell
$ terraform init

# Initializing the backend...
# 
# Initializing provider plugins...
# - Finding hashicorp/aws versions matching "~> 3.47.0"...
# - Installing hashicorp/aws v3.47.0...
# - Installed hashicorp/aws v3.47.0 (signed by HashiCorp)
# 
# Terraform has created a lock file .terraform.lock.hcl to record the provider
# selections it made above. Include this file in your version control repository
# so that Terraform can guarantee to make the same selections by default when
# you run "terraform init" in the future.
# 
# Terraform has been successfully initialized!
# 
# You may now begin working with Terraform. Try running "terraform plan" to see
# any changes that are required for your infrastructure. All Terraform commands
# should now work.
# 
# If you ever set or change modules or backend configuration for Terraform,
# rerun this command to reinitialize your working directory. If you forget, other
# commands will detect it and remind you to do so if necessary.
```

Check the plan of Terraform for this project. It should look similar to the following if all is good:

```shell
$ terraform plan

#
# ...
# Plan: 7 to add, 0 to change, 0 to destroy.
# 
# Changes to Outputs:
# + ansible-engine = (known after apply)
# + ansible-node-1 = (known after apply)
# + ansible-node-2 = (known after apply)
# + ansible-node-3 = (known after apply)
```

Apply the proposed plan if you are happy with it.
> Note: Creation of the four `t2.micro` EC2 instances will lead to some moderate AWS costs. Please do not forget to [remove all](#6-dangerous-zone---removal-of-the-sample-data-centre) after you finish experimenting.
 
Enter "yes" when asked. This step will spin up all the sample Data Centre resources in your AWS Account.

```shell
$ terraform apply

# 
# ...
# Do you want to perform these actions?
#   Terraform will perform the actions described above.
#   Only 'yes' will be accepted to approve.
# 
#   Enter a value: yes
# 
```

Actual execution will take 10-15 minutes. You will be periodically informed about provisioning of the [ansible-engine.tf](sample-infra%2Fansible-engine.tf) EC2 instance virtual machine, according to its [user-data-ansible-engine-with-eda.sh](sample-infra%2Fuser-data-ansible-engine-with-eda.sh). The latter installs the needed for Event Driven Ansible dependencies, inclusive of Python 3.9.

Here is a sample snippet of such a periodic update from `terraform apply`:

```
...
aws_instance.ansible-engine (remote-exec): Waiting, attempt #4/35, retrying in 20 seconds...
aws_instance.ansible-engine: Still creating... [1m40s elapsed]
aws_instance.ansible-engine: Still creating... [1m50s elapsed]
aws_instance.ansible-engine (remote-exec): PROGRESS:
aws_instance.ansible-engine (remote-exec): *********
aws_instance.ansible-engine (remote-exec):   Installing : git-core-doc-2.40.1-1.amzn2.0.1.noarch                      9/21
aws_instance.ansible-engine (remote-exec):   Installing : fontconfig-2.13.0-4.3.amzn2.x86_64                         10/21
aws_instance.ansible-engine (remote-exec):   Installing : dejavu-sans-mono-fonts-2.33-6.amzn2.noarch                 11/21
aws_instance.ansible-engine (remote-exec):   Installing : dejavu-serif-fonts-2.33-6.amzn2.noarch                     12/21
aws_instance.ansible-engine (remote-exec):   Installing : 1:perl-Error-0.17020-2.amzn2.noarch                        13/21
aws_instance.ansible-engine (remote-exec):   Installing : alsa-lib-1.1.4.1-2.amzn2.x86_64                            14/21
aws_instance.ansible-engine (remote-exec):   Installing : log4j-cve-2021-44228-hotpatch-1.3-7.amzn2.noarch           15/21
aws_instance.ansible-engine (remote-exec): Created symlink from /etc/systemd/system/multi-user.target.wants/log4j-cve-2021-44228-hotpatch.service to /usr/lib/systemd/system/log4j-cve-2021-44228-hotpatch.service.
...
```

If all went well, it should result in something like the following:

```
...

aws_instance.ansible-engine (remote-exec): PLAY RECAP *********************************************************************
aws_instance.ansible-engine (remote-exec): ansible-engine             : ok=19   changed=17   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
aws_instance.ansible-engine (remote-exec): node1                      : ok=8    changed=7    unreachable=0    failed=0    skipped=11   rescued=0    ignored=0
aws_instance.ansible-engine (remote-exec): node2                      : ok=8    changed=7    unreachable=0    failed=0    skipped=11   rescued=0    ignored=0
aws_instance.ansible-engine (remote-exec): node3                      : ok=8    changed=7    unreachable=0    failed=0    skipped=11   rescued=0    ignored=0

aws_instance.ansible-engine: Creation complete after 10m21s [id=i-0dab06d54e2bdc870]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

ansible-engine = "54.206.175.29"
ansible-node-1 = "3.25.54.116"
ansible-node-2 = "13.211.228.54"
ansible-node-3 = "54.252.188.204"
```

The "PLAY RECAP" section above shows the final statistics for execution of the [configure-datacentre.yaml](sample-infra%2Ffiles-for-upload%2Fconfigure-datacentre.yaml) playbook, which is the Ansible-defined configuration of the sample Data Centre. The playbook gets executed automatically after the initial provisioning by Terraform.

Please save the resulting IP addresses for the EC2 instances (virtual machines) in a text file. In our case above, they are as follows (will be different when you run yourself):
```
Outputs:

ansible-engine = "54.206.175.29"
ansible-node-1 = "3.25.54.116"
ansible-node-2 = "13.211.228.54"
ansible-node-3 = "54.252.188.204"
```

You will use them to ssh into them using the above-mentioned `ssh_pair_private_key`. That private key path was specified in the [variables.tf](./sample-infra/variables.tf). In our case, the value is:
* `~/.ssh/automation-samples`

Try ssh into the "ansible-engine" machine as follows, type `yes` when asked:
```shell
$ ssh -i ~/.ssh/automation-samples devops@54.206.175.29
# The authenticity of host '54.206.175.29 (54.206.175.29)' can't be established.
# ED25519 key fingerprint is SHA256:ZCc7ex6vLRIP/fegV0g7b09gAB4JueeeR4rGoQmStd4.
# This key is not known by any other names
# Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
# Warning: Permanently added '54.206.175.29' (ED25519) to the list of known hosts.
# 
#        __|  __|_  )
#        _|  (     /   Amazon Linux 2 AMI
#       ___|\___|___|
# 
# https://aws.amazon.com/amazon-linux-2/
[devops@ansible-engine ~]$ 
```

Congratulations! You are on the primary virtual machine of the sample Date Centre.

The following files should be there:

`[devops@ansible-engine ~]$ ls -1`
```
ansible.cfg
get-automation-sample-playbooks.sh
inventory.yaml
openshift-prepare.sh
webhook-prepare.sh
```

The needed for Ansible files have been prepared for you on the "ansible-engine" machine. They are the `ansible.cfg` configuration file and the `inventory.yaml` static inventory file. They should look as follows:

`[devops@ansible-engine ~]$ cat ansible.cfg`
```
[defaults]
inventory = ./inventory.yaml
host_key_checking = False
remote_user = devops
```

`[devops@ansible-engine ~]$ cat inventory.yaml`
```yaml
all:
  children:
    ansible:
      hosts:
        ansible-engine:
          ansible_host: ip-172-31-12-216.ap-southeast-2.compute.internal
          ansible_connection: local
          ansible_python_interpreter: /usr/local/bin/python3.9
          haproxy_public_ip: 54.252.188.204
    nodes:
      hosts:
        node1:
          ansible_host: ip-172-31-2-0.ap-southeast-2.compute.internal
        node2:
          ansible_host: ip-172-31-15-111.ap-southeast-2.compute.internal
        node3:
          ansible_host: ip-172-31-12-225.ap-southeast-2.compute.internal
    web:
      hosts:
        node1:
        node2:
    loadbalancer:
      hosts:
        node3:
  vars:
    ansible_user: devops
    ansible_password: devops
    ansible_connection: ssh
    ansible_python_interpreter: /usr/bin/python2
    ansible_ssh_private_key_file: /home/devops/.ssh/id_rsa
    ansible_ssh_extra_args: ' -o StrictHostKeyChecking=no '
```

[TOC](#table-of-contents)

## Step 1.6. Verify all

Let's verify all the created machines are under Ansible control.

It is time to get the sample playbooks onto the "ansible-engine" machine. Run the following:

`[devops@ansible-engine ~]$ ./get-automation-sample-playbooks.sh`

It should give execution log as follows:
```
+ git clone --depth 1 --branch main https://github.com/mikhailknyazev/automation-samples.git automation-samples
Cloning into 'automation-samples'...
remote: Enumerating objects: 73, done.
remote: Counting objects: 100% (73/73), done.
remote: Compressing objects: 100% (60/60), done.
remote: Total 73 (delta 2), reused 69 (delta 1), pack-reused 0
Receiving objects: 100% (73/73), 55.12 KiB | 9.19 MiB/s, done.
Resolving deltas: 100% (2/2), done.
+ sleep 1
+ rm -rf roles
+ mv -f automation-samples/sample-playbooks/app-deploy.yaml automation-samples/sample-playbooks/haproxy-local-check.sh automation-samples/sample-playbooks/haproxy-plus-health-checker.yaml automation-samples/sample-playbooks/health-checker.yaml automation-samples/sample-playbooks/ping-all.yml automation-samples/sample-playbooks/roles automation-samples/sample-playbooks/rolling-update.yaml automation-samples/sample-playbooks/webhook-for-rolling-update.yaml .
+ rm -rf automation-samples/
```

Have a look at the newly retrieved playbooks / rulebooks in the same folder:

`[devops@ansible-engine ~]$ ls -t1`
```
# New ones
app-deploy.yaml
haproxy-local-check.sh
haproxy-plus-health-checker.yaml
health-checker.yaml
ping-all.yml
roles
rolling-update.yaml
webhook-for-rolling-update.yaml

# Older ones
inventory.yaml
webhook-prepare.sh
openshift-prepare.sh
get-automation-sample-playbooks.sh
ansible.cfg
```

Let's run the following to check Ansible and Event Driven Ansible are healthy on the "ansible-engine" machine:

Ansible first:

`[devops@ansible-engine ~]$ ansible-playbook --version`

The expected output should be as follows:
```
ansible-playbook [core 2.15.2]
  config file = /home/devops/ansible.cfg
  configured module search path = ['/home/devops/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/local/lib/python3.9/site-packages/ansible
  ansible collection location = /home/devops/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/local/bin/ansible-playbook
  python version = 3.9.17 (main, Aug 12 2023, 11:23:15) [GCC 7.3.1 20180712 (Red Hat 7.3.1-15)] (/usr/local/bin/python3.9)
  jinja version = 3.1.2
  libyaml = True
```

And Event Driven Ansible second:

`[devops@ansible-engine ~]$ ansible-rulebook --version`

The expected output should be as follows:
```
__version__ = '1.0.1'
  Executable location = /usr/local/bin/ansible-rulebook
  Drools_jpy version = 0.3.4
  Java home = /usr/lib/jvm/java-17-amazon-corretto.x86_64
  Java version = 17.0.8
  Python version = 3.9.17 (main, Aug 12 2023, 11:23:15) [GCC 7.3.1 20180712 (Red Hat 7.3.1-15)]
```

Now, let's execute a simple playbook which pings all the hosts in the inventory `/home/devops/inventory.yaml`:

Here is the playbook:

`[devops@ansible-engine ~]$ cat ping-all.yml`
```yaml
---
- name: Ping all hosts
  hosts: all
  tasks:
    - name: Ping
      ansible.builtin.ping:
```

Let's execute it as follows:

`[devops@ansible-engine ~]$ ansible-playbook ping-all.yml`

The expected output:
```
PLAY [Ping all hosts] *******************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************
ok: [ansible-engine]
ok: [node3]
ok: [node2]
ok: [node1]

TASK [Ping] *****************************************************************************************************************************************
ok: [node3]
ok: [node1]
ok: [node2]
ok: [ansible-engine]

PLAY RECAP ******************************************************************************************************************************************
ansible-engine             : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node3                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

[TOC](#table-of-contents)

# 2. Deploy the sample App

We need to execute the following for the `web` group in the inventory:
```yaml
...
web:
  hosts:
    node1:
    node2:
...
```

`[devops@ansible-engine ~]$` ansible-playbook [app-deploy.yaml](sample-playbooks%2Fapp-deploy.yaml)

The expected output:
```
...
TASK [Verify application health] ****************************************************************************************************************************
ok: [node2 -> localhost]
ok: [node1 -> localhost]

TASK [Check if 'Serving from...' is in the response] ********************************************************************************************************
ok: [node1 -> localhost] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [node2 -> localhost] => {
    "changed": false,
    "msg": "All assertions passed"
}

PLAY RECAP **************************************************************************************************************************************************
node1                      : ok=20   changed=14   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2                      : ok=20   changed=14   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

In your browser, navigate to the previously saved IP addresses of the node1 and node2 (Web UI of the sample App instances):

`ansible-node-1 = "3.25.54.116"`
![initial_node1.png](images%2Finitial_node1.png)

`ansible-node-2 = "13.211.228.54"`
![initial_node2.png](images%2Finitial_node2.png)

[TOC](#table-of-contents)

# 3. Deploy the HAProxy load balancer and Health Checker

# 3.1. Developer Sandbox OpenShift environment

The Health Checker will be deployed into a standard "Developer Sandbox" OpenShift environment. Hence, you need to register there first if not already:
* https://developers.redhat.com/developer-sandbox

After registration, you should have access to your project in the "Developer Sandbox" as follows:
![initial_oc.png](images%2Finitial_oc.png)

Tap the question mark icon in the top-right. Choose "Command line tools". Tap the "Copy login command" link. Go ahead with the login. Tap "Display token". Copy your values from the screen:

```
Log in with this token

oc login --token=sha256~812G1w6UioKITX-95sV7vUoPptCasa0jjhsdjhdViQt --server=https://api.sandbox-n3.k4ri.p2.openshiftapps.com:6443
```

In the next preparation step you will need the following values from above:
* `openshift_host`: sandbox-n3.k4ri.p2.openshiftapps.com
* `openshift_token`: sha256~812G1w6UioKITX-95sV7vUoPptCasa0jjhsdjhdViQt

Run using your values:

`[devops@ansible-engine ~]$` ./[openshift-prepare.sh](sample-infra%2Ffiles-for-upload%2Fopenshift-prepare.sh) <openshift_host> <openshift_token>

The expected output:
```
OpenShift Host is: sandbox-n3.k4ri.p2.openshiftapps.com
OpenShift Token is: sha2...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  135M  100  135M    0     0  7060k      0  0:00:19  0:00:19 --:--:-- 8012k
oc
Logged into "https://api.sandbox-n3.k4ri.p2.openshiftapps.com:6443" as "USERNAME" using the token provided.

You have one project on this server: "USERNAME-dev"

Using project "USERNAME-dev".
Client Version: 4.13.0-202304190216.p0.g92b1a3d.assembly.stream-92b1a3d
Kustomize Version: v4.5.7
Server Version: 4.13.1
Kubernetes Version: v1.26.3+b404935

Created:
/home/devops/openshift-vars.yaml
```

Double-check you now have the `oc` OpenShift CLI installed and configured for access to your sandbox OpenShift project (namespace):

`[devops@ansible-engine ~]$ oc get pods`

The expected output:
```
No resources found in USERNAME-dev namespace.
```

[TOC](#table-of-contents)

# 3.2. Deploy the components

The following playbook installs the HAProxy load balancer onto the `node3` machine in the sample Data Centre. After it, it deploys the [sample-health-checker](sample-health-checker) Express.js app importing the following playbook as its last step: [health-checker.yaml](sample-playbooks%2Fhealth-checker.yaml)

`[devops@ansible-engine ~]$` ansible-playbook [haproxy-plus-health-checker.yaml](sample-playbooks%2Fhaproxy-plus-health-checker.yaml)

The expected output:
```
...
TASK [Display the URL to access the Health-Checker] *************************************************************************************************
ok: [ansible-engine] => {
    "msg": "http://sample-health-checker-USERNAME-dev.apps.sandbox-n3.k4ri.p2.openshiftapps.com/health"
}

PLAY RECAP ******************************************************************************************************************************************
ansible-engine             : ok=9    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node3                      : ok=11   changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
```

Navigate to your URL of the Health Checker shown in the end of the playbook run.
In this example, it is as follows:
* http://sample-health-checker-USERNAME-dev.apps.sandbox-n3.k4ri.p2.openshiftapps.com/health

Notice the IP address for node3 (`ansible-node-3 = "54.252.188.204"`), it is mentioned in the following text in the Health Checker UI:
* "The target HAProxy in front of the sample App instances is at `54.252.188.204`. Monitoring is live"

Also, the responses are delivered from either `node1` or `node2` -- depending on how the HAProxy load balancer balances the load of the call from the Health Checker.
![health-checker-01.png](images%2Fhealth-checker-01.png)

You can actually navigate to the IP of the HAProxy Load Balancer and see content delivered, either from `node1` or `node2`: `http://54.252.188.204`

[TOC](#table-of-contents)

# 4. Simple rolling update of the App

The following playbook performs sequential update of `node1` and then `node2` behind the HAProxy.

Notice `serial: 1` in its top. It ensures the logic gets applied to the hosts in group `"web"` one-by-one.
```yaml
---
- name: Rolling Update
  hosts: "web"
  become: yes
  serial: 1
...
```
Also, when corresponding node is temporarily "offline", the following updates Linux packages on the box to the latest versions. It demonstrates how patching can be done during rolling update:
```yaml
...
- name: Update all packages
  ansible.builtin.yum:
    name: '*'
    state: latest
...
```

What about the sample App update? We will instruct the [rolling-update.yaml](sample-playbooks%2Frolling-update.yaml) playbook to use a non-main branch via overriding its `application_branch: main` variable right from the command line. This repository has branch `sample-app-v2`, where [index.html](sample-app%2Findex.html) of the App has the following extra line after `SERVER_DETAILS`:
```html
<!DOCTYPE html>
<html>
...
    <h2>Welcome to our sample App</h2>
    <h2>
        SERVER_DETAILS
        Version 2 of the App
    </h2>
...
</html>
```

Let's start the following and immediately refresh the Health Checker UI in your browser to clear screen:

`[devops@ansible-engine ~]$` ansible-playbook [rolling-update.yaml](sample-playbooks%2Frolling-update.yaml) --extra-vars application_branch=sample-app-v2

The expected output when it completes is as follows:
```
...
PLAY RECAP ******************************************************************************************************************************************
node1                      : ok=18   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2                      : ok=18   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node3                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

And the Health Checker UI should show some interesting details, in particular:
* First, `node1` got under maintenance, so traffic was served from `node2` (old branch "main")
* Second, `node1` got updated so responses from it mention the new branch "sample-app-v2". You can see the "Version 2 of the App" strings correspondingly.
* At the same time, `node2` got under maintenance.
* Finally, both `node1` and `node2` are serving version 2 of the App.

![health-checker-02.png](images%2Fhealth-checker-02.png)

[TOC](#table-of-contents)

# 5. GitOps-style rolling update of the App from a different GitHub repository

The following video (no sound) demonstrates the explained in section "5.2. Run the components" below.

[![](https://markdown-videos-api.jorgenkh.no/youtube/tovjvDNyR6k)](https://youtu.be/tovjvDNyR6k)

## 5.1. Prepare a different GitHub repository for sample App

Create a new **public** repository, e.g. `sample-app-test`, on GitHub (opt to create the initial `README.md` so that the `main` branch gets initialised) and configure a Webhook for it as follows:
![github-01.png](images%2Fgithub-01.png)

Note the following:
* The `Payload URL` points to port `5000` of the "ansible-engine" machine: `http://54.206.175.29:5000/endpoint` . **It is where Event Driven Ansible will be waiting for corresponding HTTP calls from GitHub.**
* The `Content type` selected is `application/json`
* Question "Which events would you like to trigger this webhook?" answered with `Just the push event.`

Add the **whole directory** [sample-app](sample-app) to the root of the `main` branch in the new repository. For example, you can do it right in GitHub UI:
* Choose "Upload files"
  ![github-02.png](images%2Fgithub-02.png)
* Drag&Drop the whole "sample-app" folder from your OS into the newly created repo, e.g.: https://github.com/mikhailknyazev/sample-app-test
  ![github-03.png](images%2Fgithub-03.png)
* Choose "Commit"
* Verify you have the App in the directory `sample-app` in the new repository:
  ![github-04.png](images%2Fgithub-04.png)

[TOC](#table-of-contents)

## 5.2. Run the components

First, prepare your values as follows:
* `application_repo`: It is your new GitHub repository you just added the `sample-app` folder into. It should look similar to: `https://github.com/mikhailknyazev/sample-app-test`
* `application_branch`: It should likely be `main`

Run the following using your values:

`[devops@ansible-engine ~]$` ./[webhook-prepare.sh](sample-infra%2Ffiles-for-upload%2Fwebhook-prepare.sh) <application_repo> <application_branch>

The expected output:
```
---
application_repo: https://github.com/mikhailknyazev/sample-app-test
application_branch: main
application_branch_in_webhook_event: refs/heads/main
subfolder_path: sample-app

Created:
/home/devops/webhook-vars.yaml
```

Now start the rulebook with Event Driven Ansible:

`[devops@ansible-engine ~]$` ansible-rulebook --rulebook [webhook-for-rolling-update.yaml](sample-playbooks%2Fwebhook-for-rolling-update.yaml) -i inventory.yaml --vars webhook-vars.yaml

It should start and stay silent.

It is time to do some GitOps with the App!

Navigate to the `index.html` of the App in the new repository and tap the "Edit" button.
![gitops-01.png](images%2Fgitops-01.png)

> **WARNING**: Keep the `SERVER_DETAILS` string there -- it is updated by Ansible during deployments and eventually used for health checking. Add your custom content on lines **after** line with `SERVER_DETAILS`

Before tapping "Commit changes...", double-check the console with the `ansible-rulebook...` command running. Also, refresh your Health Checker screen in browser -- it will be soon showing progress of the GitOps-driven rolling update with Ansible!

Commit the changes.

Now you can see Even Driven Ansible started the [rolling-update.yaml](sample-playbooks%2Frolling-update.yaml) playbook with corresponding variables overridden:
![gitops-03.png](images%2Fgitops-03.png)

Also, the Health Checker is tracking the updates correspondingly:
![gitops-04.png](images%2Fgitops-04.png)

[TOC](#table-of-contents)

# 6. Dangerous zone - removal of the sample Data Centre

When you are done with your experiments, destroy the resources created for the sample Data Centre in your AWS account. On your local computer, change directory into `automation-samples/sample-infra`:

```shell
$ pwd
# /Users/myusername/.../automation-samples/sample-infra
```

> **WARNING:** If you want to drop the resources according to the presented by Terraform plan indeed, then run the following and type `yes` when asked:
```shell
terraform destroy
```

[TOC](#table-of-contents)
