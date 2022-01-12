#!/bin/bash

# 0. Loading Variables
source conf/config.sh

echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'cat conf/hosts >> /etc/hosts'

ssh-keygen -t rsa -f ~/.ssh/id_rsa # generate ssh key for the node
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

#HOSTNAMES=`awk '{print $2}' conf/hosts` # get all hostnames in conf/hosts file

# for hostname in $HOSTNAMES
# do
# 	ssh-copy-id $hostname # copy node ssh public key to all nodes in the cluster
# done
