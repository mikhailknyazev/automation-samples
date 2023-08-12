#! /bin/bash
amazon-linux-extras install -y epel
useradd devops
echo -e 'devops\ndevops' | sudo passwd devops
echo 'devops ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/devops
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
systemctl restart sshd.service

