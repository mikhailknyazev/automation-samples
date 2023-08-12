#! /bin/bash

# The loop below runs until the "ansible-galaxy" command finds the "ansible.eda" collection.
# (which is the expected result of a final step in the User Data script: user-data-ansible-engine-with-eda.sh)
# After the loop, the script runs "ansible-playbook configure-datacentre.yaml" if all is good.

count=0
total=35

until sudo -u devops /usr/local/bin/ansible-galaxy collection list 2> /dev/null | grep "ansible.eda" || ((count++>=total))
do
    echo
    echo "Waiting, attempt #$count/$total, retrying in 20 seconds..."
    sleep 20
    echo "PROGRESS:"
    echo "*********"
    tail -n 8 ./userdata.log
    echo
    echo "*********"
done

if ((count<total))
then
    ansible-playbook configure-datacentre.yaml
else
    echo "timed out"
fi
