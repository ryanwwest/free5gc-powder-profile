# free5gc-powder-profile

This is a [POWDER](https://powderwireless.net/) profile that automatically instantiates a full simulated 5g core network and UE RAN. It uses [free5gc](https://github.com/free5gc/free5gc) for the 5c core, spread across 4 physical nodes, and uses [UERANSIM](https://github.com/aligungr/UERANSIM) to simulate a gNB and UE devices on a fifth physical node.

This profile instructs powder to set up the 5 nodes, then runs scripts on each node to install necessary software and configurations. 

It then tests the network with a test UE device, and outputs a file on that node with the results. (This part is WIP)

The free5gc nodes are intended to be set up following example 2 on this page: https://github.com/free5gc/free5gc/wiki/SMF-Config.

![](https://camo.githubusercontent.com/535a285fe7bb0d6ca44bb1ccbbb3e7ea7bd5707b6f5a025a77309b481b58c5ea/68747470733a2f2f692e696d6775722e636f6d2f4a3957504638712e706e67)

See https://github.com/lbstoller/my-profile for an example/information about POWDER/CloudLab repo-based profiles.
