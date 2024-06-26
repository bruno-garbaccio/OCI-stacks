#!/bin/bash
#
# Cluster init configuration script
#

#
# wait for cloud-init completion on the jupyter host
#
execution=1

ssh_options="-i ~/.ssh/cluster.key -o StrictHostKeyChecking=no"
sudo cloud-init status --wait

source /etc/os-release

# sudo dnf install oracle-epel-release-el8
sudo dnf install ansible -y

ansible-galaxy collection install ansible.netcommon:=2.5.1 --force > /dev/null
ansible-galaxy collection install community.general:=4.8.1 --force > /dev/null
ansible-galaxy collection install ansible.posix > /dev/null

threads=$(nproc)
forks=$(($threads * 8))

sudo sed -i "s/^#forks.*/forks = ${forks}/" /etc/ansible/ansible.cfg
sudo sed -i "s/^#fact_caching=.*/fact_caching=jsonfile/" /etc/ansible/ansible.cfg
sudo sed -i "s/^#fact_caching_connection.*/fact_caching_connection=\/tmp\/ansible/" /etc/ansible/ansible.cfg
sudo sed -i "s/^#bin_ansible_callbacks.*/bin_ansible_callbacks=True/" /etc/ansible/ansible.cfg
sudo sed -i "s/^#stdout_callback.*/stdout_callback=yaml/" /etc/ansible/ansible.cfg
sudo sed -i "s/^#retries.*/retries=5/" /etc/ansible/ansible.cfg
sudo sed -i "s/^#connect_timeout.*/connect_timeout=300/" /etc/ansible/ansible.cfg
sudo sed -i "s/^#command_timeout.*/command_timeout=120/" /etc/ansible/ansible.cfg
