#!/usr/bin/env bash

printf "\n"

echo "*************************************"
echo "*   Hadoop Cluster Setup (5 steps)  *"
echo "*************************************"

# 0. Loading Variables
source conf/config.sh

# 1. Installing & Configuring SSH
echo $HADOOP_USER_PASSWORD | sudo -S apt install openssh-server openssh-client -y
echo ">>>> 1. Enabling SSH paswordless connection... <<<<"

printf "<<<< 1. done. \n\n"

# Installing Java 8
echo ">>>> 2. Installing Java... <<<<"

echo $HADOOP_USER_PASSWORD | sudo -S add-apt-repository ppa:openjdk-r/ppa
echo $HADOOP_USER_PASSWORD | sudo -S apt update
echo $HADOOP_USER_PASSWORD | sudo -S apt install openjdk-8-jdk -y
echo $HADOOP_USER_PASSWORD | sudo -S apt install openjdk-8-jdk-headless -y

printf "<<<< 2. done. \n\n"

# Installing Hadoop ${HADOOP_VERSION}
echo ">>>> 3. Installing Hadoop... <<<<"

wget $HADOOP_ORIGIN
echo $HADOOP_USER_PASSWORD | sudo -S tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C $HADOOP_PARENT_DIR && rm -rf hadoop-${HADOOP_VERSION}.tar.gz

printf "<<<< 3. done. \n\n"

# Configuring Hadoop
echo ">>>> 4. Configuring Hadoop... <<<<"

echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'mkdir /opt/hadoop'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'mkdir /opt/hadoop/namenode'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'mkdir /opt/hadoop/datanode'

echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'

echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export HDFS_DATANODE_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export HDFS_SECONDARYNAMENODE_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export YARN_RESOURCEMANAGER_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export YARN_NODEMANAGER_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export HDFS_NAMENODE_USER=root" >> $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/hadoop-env.sh'

echo $HADOOP_USER_PASSWORD | sudo -S cp conf/hadoop/* $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/
echo $HADOOP_USER_PASSWORD | sudo -S chown hadoop $HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}

printf "<<<< 4. done. \n\n"

# Updating .bashrc
echo ">>>> 5. Updating .bashrc... <<<<"

## Add and export Java
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "JAVA_HOME=$JAVA_HOME" >> ~/.bashrc'
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export JAVA_HOME" >> ~/.bashrc'
## Set PSDSH type to ssh
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'echo "PDSH_RCMD_TYPE=ssh" >> ~/.bashrc'
## set Hadoop home directory
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "HADOOP_HOME=$HADOOP_PARENT_DIR/hadoop-${HADOOP_VERSION}" >> ~/.bashrc'
## Update and export PATH
echo $HADOOP_USER_PASSWORD | sudo -S bash -c "source conf/config.sh && echo PATH='$'PATH:'$'HADOOP_HOME/bin:'$'HADOOP_HOME/sbin >> ~/.bashrc"
echo $HADOOP_USER_PASSWORD | sudo -S bash -c 'source conf/config.sh && echo "export PATH" >> ~/.bashrc'
## Load bash profile changes into current terminal session
source ~/.bashrc
printf "<<<< 5. done. \n\n"
