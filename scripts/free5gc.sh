#!/bin/bash

# This script installs free5gc and its prerequisites on all 3 upf nodes and the free5gc core node, then runs them. Configs still need to be adjusted.

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e


echo "1. Install gtp5g Linux module"
cd ~
git clone -qb v0.2.0 https://github.com/PrinzOwO/gtp5g.git
cd gtp5g
make
sudo make install

echo "2. Install Golang Version 1.14.4"
wget -q https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz
sudo tar -C /usr/local -zxf go1.14.4.linux-amd64.tar.gz
mkdir -p ~/go/{bin,pkg,src}

echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin' >> ~/.bashrc
source ~/.bashrc
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOPATH/bin:$GOROOT/bin:/usr/local/go/bin


echo "Install free5gc Dependencies"
echo "3. Install Control-Plane Supporting Packagaes. Not required for the UPF nodes."
sudo apt -y -q update
sudo apt -y -q install mongodb wget git
sudo systemctl start mongodb

echo "4. Install User-Plane Supporting packages"
sudo apt -yq update

sudo apt remove cmdtest
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
# added yarn
sudo apt -yq install git gcc cmake autoconf libtool pkg-config libmnl-dev libyaml-dev yarn nodejs

echo "4a. go get"
env
go env
echo ".............."
export GOCACHE="$HOME/.cache/go-build"
go get -u github.com/sirupsen/logrus


echo "Configure Linux Network Settings"
echo "5. Enable IP forwarding on Linux"
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -A FORWARD -j ACCEPT
echo "6. Configure NAT to allow UEs connected to access the Internet."
iface=`cat /var/emulab/boot/controlif`
sudo iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE

echo "7. Stop firewall service so it doesn't interfere with anything."
sudo systemctl stop ufw


echo "Install free5gc"
echo "8. Clone the free5gc repository."
cd ~
git clone --recursive -b v3.0.5 -j `nproc` https://github.com/free5gc/free5gc.git
#git clone --recursive -b v3.0.4  https://github.com/ralfkundel/free5gc.git
# NOTE: free5gc v3.0.4 has bug where the gNodeB of the external RAN, UERANSIM, doesn't know a PDU session has been established due to incorrect messages within the free5gc core. However, another GitHub user, ralfkundel, has created a fork of free5gc fixing this issue amongst others such that it works with UERANSIM. Therefore, in the previous command, I am using the forked version of free5gc that is working.
# If free5gc is still on v3.0.4, I recommend using the fork. You can also follow this issue I opened with free5gc about this bug to see if it's fixed. The creator of the fork, ralfkundel, is also working with them to get his fixes integrated into the newer versions of free5gc.

echo "9. Install all free5gc Golang module dependencies."
cd ~/free5gc
#/usr/local/go/bin/go mod download
#go mod download

echo "10. Compile free5gc network function services (AMF, SMF, etc)"
# run a different command if this is the free5gc node
host=$(hostname | sed 's/\..*//')
echo Node host = "$host"
if [ "free5gc" == "$host" ] ; then 
	echo "--This is the free5gc node--"
	make all
	# open question - will the configs and folders already exist when changing them? if not I may need to run, stop, then modify and run again
	cd ~/free5gc
	cp /local/repository/config/*.conf /local/repository/config/uerouting.yaml config/
	./run.sh
# these are for all 3 UPF nodes
else 
	echo "--This is one of the 3 upf nodes--"
	cd ~/free5gc
	make upf
	cd ~/free5gc/NFs/upf/build
	if [ "$host" == "upf1" ]; then
		cp /local/repository/config/upfcfg1.yaml config/upfcfg.yaml
	elif [ "$host" == "upf2" ]; then
		cp /local/repository/config/upfcfg2.yaml config/upfcfg.yaml
	elif [ "$host" == "upfb" ]; then
		cp /local/repository/config/upfcfgb.yaml config/upfcfg.yaml
	else
		echo "error: no config matches host $host"
		exit 1
	fi
	sudo -E ./bin/free5gc-upfd
fi
