#!/bin/bash

# only for manual use for now

cd UERANSIM/
./nr-cli gnb-create
./nr-cli ue-create
./nr-cli ue-list
./nr-cli ue-status 208930000000003
sudo ./nr-cli session-create 208930000000003
./nr-cli ue-status 208930000000003
./nr-cli ue-ping 208930000000003 google.com -c 3
