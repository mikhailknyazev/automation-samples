#! /bin/bash
exec > >(tee /home/ec2-user/userdata.log) 2>&1

amazon-linux-extras install -y epel
useradd devops
echo -e 'devops\ndevops' | sudo passwd devops
echo 'devops ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/devops
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
systemctl restart sshd.service

yum update -y
yum install -y vim git wget java-17-amazon-corretto-devel sshpass

yum -y groupinstall "Development Tools"
yum -y install openssl-devel bzip2-devel libffi-devel

wget https://www.python.org/ftp/python/3.9.17/Python-3.9.17.tgz
tar xvf Python-3.9.17.tgz
cd Python-*/
./configure --enable-optimizations
make altinstall

cd ~
python3.9 --version
pip3.9 --version

/usr/local/bin/python3.9 -m pip install --upgrade pip
pip3.9 --version
pip3.9 install ansible-rulebook ansible ansible-runner wheel openshift

# Note: we are opening port 5000 for incoming webhook calls on port 5000
yum install -y firewalld
systemctl enable --now firewalld
firewall-cmd --add-port=5000/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-ports

sudo -u devops /usr/local/bin/ansible-galaxy collection install community.general ansible.eda
