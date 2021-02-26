#!/bin/bash

# This script installs UERANSIM and its prerequisites on the ran node as root user then runs it. Configs still need to be adjusted.

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# automate grub prompt during installation
echo "SET grub-pc/install_devices /dev/sda" | sudo debconf-communicate


echo "1. Install the UERANSIM dependencies."
cd ~
sudo apt -y --force-yes update 
DEBIAN_FRONTEND=noninteractive sudo apt -y --force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt -y --force-yes install make g++ openjdk-11-jdk maven libsctp-dev lksctp-tools snapd
# getting cmake from apt installs an old version of cmake, so we have to get it from snap
sudo snap install cmake --classic
# maybe gets rid of grub popup manual enter req
# https://askubuntu.com/questions/146921/how-do-i-apt-get-y-dist-upgrade-without-a-grub-config-prompt

#echo "2. Set the JAVA_HOME environment variable."
#export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

echo "3. Clone UERANSIM."
cd ~
git clone https://github.com/aligungr/UERANSIM.git

echo "4. Change configs"
cp /local/repository/config/ueran-profile.yaml ~/UERANSIM/config/profile.yaml
cp /local/repository/config/ueran-gnb.yaml ~/UERANSIM/config/free5gc-gnb.yaml

echo "4.Build UERANSIM"
cd ~/UERANSIM
make
