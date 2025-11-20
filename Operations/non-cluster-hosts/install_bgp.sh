#!/bin/bash

PATH="/home/tigera/Calico-Non-Cluster-Nodes-Workshop/BGP"
SSH="/usr/bin/ssh"
SCP="/usr/bin/scp"

case $1 in
    "nonk8s1")
        $SCP $PATH/bird.service ubuntu@ip-10-0-1-32.ca-central-1.compute.internal:/home/ubuntu
        $SCP $PATH/bird.conf.$1 ubuntu@ip-10-0-1-32.ca-central-1.compute.internal:/home/ubuntu/bird.conf
        $SCP $PATH/bird-2.16.1-1.el9.x86_64.rpm ubuntu@ip-10-0-1-32.ca-central-1.compute.internal:/home/ubuntu/bird-2.16.1-1.el9.x86_64.rpm
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo yum install ./bird-2.16.1-1.el9.x86_64.rpm -y
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo mv bird.conf /etc/bird.conf 
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo chown root:bird /etc/bird.conf
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo cp bird.service /lib/systemd/system
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo chown root:root /lib/systemd/system/bird.service
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo mv bird.service /etc/systemd/system
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo chown root:root /etc/systemd/system/bird.service
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config 
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo systemctl daemon-reload
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo systemctl enable bird.service
        echo "Restarting the server"
        $SSH ubuntu@ip-10-0-1-32.ca-central-1.compute.internal sudo reboot
        ;;
    "nonk8s2")
        $SCP $PATH/bird.service ubuntu@ip-10-0-1-33.ca-central-1.compute.internal:/home/ubuntu
        $SCP $PATH/bird.conf.$1 ubuntu@ip-10-0-1-33.ca-central-1.compute.internal:/home/ubuntu/bird.conf
        $SCP $PATH/bird-2.16.1-1.el9.x86_64.rpm ubuntu@ip-10-0-1-33.ca-central-1.compute.internal:/home/ubuntu/bird-2.16.1-1.el9.x86_64.rpm
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo yum install ./bird-2.16.1-1.el9.x86_64.rpm -y
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo mv bird.conf /etc/bird.conf 
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo chown root:bird /etc/bird.conf
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo cp bird.service /lib/systemd/system
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo chown root:root /lib/systemd/system/bird.service
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo mv bird.service /etc/systemd/system
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo chown root:root /etc/systemd/system/bird.service
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config 
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo systemctl daemon-reload
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo systemctl enable bird.service
        echo "Restarting the server"
        $SSH ubuntu@ip-10-0-1-33.ca-central-1.compute.internal sudo reboot
        ;;
esac
