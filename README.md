# free5gc-powder-profile

This is a POWDER profile that automatically instantiates a full simulated 5g core network and UE RAN. It uses [free5gc](https://github.com/free5gc/free5gc) for the 5c core, spread across 4 physical nodes, and uses [UERANSIM](https://github.com/aligungr/UERANSIM) to simulate a gNB and UE devices on a fifth physical node.

This profile instructs powder to set up the 5 nodes, then runs scripts on each node to install necessary software and configurations. It then tests the network with a test UE device, and outputs a file on that node with the results. (WIP)

See https://github.com/lbstoller/my-profile for an example/information about POWDER/CloudLab repo-based profiles.
