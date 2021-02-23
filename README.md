# free5gc-powder-profile

This is a [POWDER](https://powderwireless.net/) profile that automatically instantiates a full simulated 5g core network and UE RAN. It uses [free5gc](https://github.com/free5gc/free5gc) v3.0.5 for the 5c core, spread across 4 physical nodes, and uses [UERANSIM](https://github.com/aligungr/UERANSIM) v3.1.1 to simulate a gNB and UE devices on a fifth physical node.

The nodes are as follows:
* sim-ran (10.10.1.1) runs UERANSIM, used as a simulated external Radio Accesss Network (RAN/gNB) and User Equipment (UE).
* free5gc (10.10.1.2) runs all free 5gc core functions.
* upfb (10.10.1.3) runs a UPF network function branching point.
* upf1 (10.10.1.4) runs a UPF anchor.
* upf2 (10.10.1.5) runs another UPF anchor.

This profile instructs powder to set up the 5 nodes, then runs scripts on each node to install necessary software and configurations. 

It then tests the network with a test UE device, and outputs a file on that node with the results. (This part is WIP)

The free5gc nodes are intended to be set up following example 2 on this page, but using the IP addresses above: https://github.com/free5gc/free5gc/wiki/SMF-Config. The image below is pulled from that page.

![Free5gc network function layout](https://camo.githubusercontent.com/69be509629703a3951dead2c2096a04fee5a46b422edb91a09f6d15eaac0d7e5/68747470733a2f2f692e696d6775722e636f6d2f744d6d324f77612e706e67)

### Additional Setup Required

This profile runs scripts that perform most of the insallation and start all free5gc nodes; however, there are a few more things that must manually be done before having a fully operational network.

* ssh to the free5gc node, cd into `free5gc/webserver`, run `go run server.go`, navigate to `https:<free5gc-ip>:5000` in a browser, login and register a UE. At the moment, you only need to change OPc to OP; every other value in the default new subscriber is already configured in the sim-ran node.
  * You can alternatively just update mongodb databases instead, see #[here](https://forum.free5gc.org/t/on-latest-v3-05-pdu-session-fails-with-has-no-pre-config-route-referred-to-previous-similar-post-no-luck/670/4?u=ryanwwest)
* ssh to the sim-ran node and update the UERANSIM/config/free5gc-ue.yaml: change the IP address under `gnbSearchList` to be 10.10.1.1.
  * TODO have script do this
* the gNB and UE(s) on the sim-ran node are not yet running. Follow https://github.com/aligungr/UERANSIM/wiki/Usage to start them up. The configs have already been configured.
  * Current issue: While the gNB connects to the 5G core fine, setting up a PDU session from the UE to the SMF on the free5gc node results in a go panic that I have not yet figured out how to resolve. It appears to be a bug in v3.0.5 and some information is found [here](https://forum.free5gc.org/t/on-latest-v3-05-pdu-session-fails-with-has-no-pre-config-route-referred-to-previous-similar-post-no-luck/670). The comment by ryanwwest gives the exact panic and some log context for the issue, though trying the solutions as of 2/23/21 on that post have not yielded any solutions.
    * The issue could be a bug or a config problem that has to do with setting up GTP tunneling and Packet Data Rule (PDR) for the PDU session within the SMF function ([see code](https://github.com/free5gc/smf/blob/eb13ffabeef1f0ca281f62113d1fde2dbaac853a/context/datapath.go#L388)). 
      * Debugging shows that on [this line](https://github.com/free5gc/smf/blob/eb13ffabeef1f0ca281f62113d1fde2dbaac853a/context/upf.go#L217), the string "dnn" being compared is "" just before the panic, meaning, this function returns `nil` at the bottom, which then sets `iface` to `nil` [here](https://github.com/free5gc/smf/blob/eb13ffabeef1f0ca281f62113d1fde2dbaac853a/context/datapath.go#L388). This then attemps to call a function on this nil `iface` [here](https://github.com/free5gc/smf/blob/eb13ffabeef1f0ca281f62113d1fde2dbaac853a/context/datapath.go#L393), which results in a nil pointer dereference and causes the panic.
      * The config file smfcfg.yaml uses `internet` as the dnn instead, so "" does not match to it. This makes me wonder if the config is set up wrong.
      * Debug printing the UPF variable reveals the following state. Noticably, `N9Interfaces` has no elements but I think it should have some, again making me wonder if I have bad config even though similar config previously worked on free5gc v3.0.4. But even if I do have a config issue, there is still a bug because a program ideally shouldn't ever panic even if the config isn't correct.
```
{                                                         
        "NodeID": {                                       
                "NodeIdType": 0,                                                                                     
                "NodeIdValue": "CgoBAw=="                
        },                                                                                                           
        "UPIPInfo": {                                     
                "Assosi": false,
                "Assoni": true,
                "Teidri": 1,
                "V6": false,
                "V4": true,
                "TeidRange": 0,               
                "Ipv4Address": "10.10.1.3",       
                "Ipv6Address": "",         
                "NetworkInstance": "aW50ZXJuZXQ=",
                "SourceInterface": 0                
        },                                                
        "UPFStatus": 2,
        "SNssaiInfos": [
                {         
                        "SNssai": {
                                "Sst": 1,
                                "Sd": "010203"
                        },                                                                                           
                        "DnnList": [                
                                {                                                                                    
                                        "Dnn": "internet",      // may only be 'internet' and not '' because I manually modified the value                                                     
                                        "DnaiList": null,
                                        "PduSessionTypes": null
                                }
                        ]                                 
                },                                        
                {                                         
                        "SNssai": {
                                "Sst": 1,
                                "Sd": "112233"
                        },                                
                        "DnnList": [
                                {
                                        "Dnn": "internet", 
                                        "DnaiList": null,
                                        "PduSessionTypes": null
                                }
                        ]                                 
                }                                         
        ],                                                
        "N3Interfaces": [                                 
                {                                         
                        "NetworkInstance": "",
                        "IPv4EndPointAddresses": [
                                "10.10.1.3"
                        ],                                
                        "IPv6EndPointAddresses": [],
                        "EndpointFQDN": ""
                }                                         
        ],                                                
        "N9Interfaces": []                                
}
```


   * It also might be necessary to manually insert the mongodb document normally created with the webserver as apparently the automatically generated one is "the webconsole was only creating one smPolicyDnnData for internet but not for ims" (see post above).

### About

See https://github.com/lbstoller/my-profile for an example/information about POWDER/CloudLab repo-based profiles.

This profile was originally derived from https://github.com/BraedenDiaz/CS6480-Project-NDN-In-5G.
