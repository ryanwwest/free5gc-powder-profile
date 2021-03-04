#!/usr/bin/env python
"""
Derived from profile created by Braeden Diaz 

This profile is the base for an end-to-end 5G network with 5 nodes.

One node for the 5G core, one for the simulated Radio Access Network (RAN),
one for the UPF branching function, one for the UPF anchor point 1, and one
for the UPF anchor point 2.
"""


#
# Standard geni-lib/portal libraries
#
import geni.portal as portal
import geni.rspec.pg as rspec
import geni.rspec.emulab as elab
import geni.rspec.igext as IG

#
# Globals
#
class GLOBALS(object):
    SITE_URN = "urn:publicid:IDN+emulab.net+authority+cm"
    # Use kernel version required by free5gc: Ubuntu 18, kernel 5.0.0-23-generic
    UBUNTU18_IMG = "urn:publicid:IDN+emulab.net+image+reu2020:ubuntu1864std50023generic"
    HWTYPE = "d430"
    SCRIPT_DIR = "/local/repository/scripts/"


def invoke_script_str(filename):
    # redirection all output to /script_output
    return "sudo bash " + GLOBALS.SCRIPT_DIR + filename + " &> ~/5g_install_script_output"

#
# This geni-lib script is designed to run in the PhantomNet Portal.
#
pc = portal.Context()

#
# Create our in-memory model of the RSpec -- the resources we're going
# to request in our experiment, and their configuration.
#
request = pc.makeRequestRSpec()

# Optional physical type for all nodes.
pc.defineParameter("phystype",  "Optional physical node type",
                   portal.ParameterType.STRING, "",
                   longDescription="Specify a physical node type (d430,d740,pc3000,d710,etc) " +
                   "instead of letting the resource mapper choose for you.")

# Retrieve the values the user specifies during instantiation.
params = pc.bindParameters()
pc.verifyParameters()



# Create the link between the `sim-gnb` and `5GC` nodes.
gNBCoreLink = request.Link("gNBCoreLink")

# Add node which will run gNodeB and UE components with a simulated RAN.
sim_ran = request.RawPC("sim-ran")
sim_ran.component_manager_id = GLOBALS.SITE_URN
sim_ran.disk_image = GLOBALS.UBUNTU18_IMG
sim_ran.hardware_type = GLOBALS.HWTYPE if params.phystype != "" else params.phystype
sim_ran.addService(rspec.Execute(shell="bash", command=invoke_script_str("ran.sh")))
gNBCoreLink.addNode(sim_ran)

# Add node that will host the 5G Core Virtual Network Functions (AMF, SMF, UPF, etc).
free5gc = request.RawPC("free5gc")
free5gc.component_manager_id = GLOBALS.SITE_URN
free5gc.disk_image = GLOBALS.UBUNTU18_IMG
free5gc.hardware_type = GLOBALS.HWTYPE if params.phystype != "" else params.phystype
free5gc.addService(rspec.Execute(shell="bash", command=invoke_script_str("free5gc.sh")))
gNBCoreLink.addNode(free5gc)

# Add node that will host the 5G Core branching UPF Virtual Network Function.
upfb = request.RawPC("upfb")
upfb.component_manager_id = GLOBALS.SITE_URN
upfb.disk_image = GLOBALS.UBUNTU18_IMG
upfb.hardware_type = GLOBALS.HWTYPE if params.phystype != "" else params.phystype
upfb.addService(rspec.Execute(shell="bash", command=invoke_script_str("free5gc.sh")))
gNBCoreLink.addNode(upfb)

# Add node that will host the UPF anchor point 1.
upf1 = request.RawPC("upf1")
upf1.component_manager_id = GLOBALS.SITE_URN
upf1.disk_image = GLOBALS.UBUNTU18_IMG
upf1.hardware_type = GLOBALS.HWTYPE if params.phystype != "" else params.phystype
upf1.addService(rspec.Execute(shell="bash", command=invoke_script_str("free5gc.sh")))
gNBCoreLink.addNode(upf1)

# Add node that will host the UPF anchor point 2.
upf2 = request.RawPC("upf2")
upf2.component_manager_id = GLOBALS.SITE_URN
upf2.disk_image = GLOBALS.UBUNTU18_IMG
upf2.hardware_type = GLOBALS.HWTYPE if params.phystype != "" else params.phystype
upf2.addService(rspec.Execute(shell="bash", command=invoke_script_str("free5gc.sh")))
gNBCoreLink.addNode(upf2)

#
# Print and go!
#
pc.printRequestRSpec(request)
