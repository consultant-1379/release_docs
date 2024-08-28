#!/bin/bash

#
# This sample script contains the commands used for a LITP installation creating
# the definition part for the following configuration:
#
# Type: Multi-Blade
#
# Config:	MS (Management Server)
#			2 SC Nodes (Service Control Nodes)
#			1 SAN (Boot block device)
#			1 NAS (SFS/NFS network filesystems)
#
# Hardware:	MS installed on stand-alone DL380
#           SC-1 on G6 blade inside enclosure atc7000-67
#           SC-2 on G8 blade inside enclosure atc7000-97
# Campaigns: Jboss
#
# Target built: SP20
#
# If your LITP hardware configuration differs from this, you will need to
# modify script to suit your own requirements.
#
# Various settings used in this sample script are environment specific,
# these include IP addresses, MAC addresses, netid, TIPC addresses,
# serial numbers, usernames, passwords etc and may also need to be
# modified to suit your requirements.
#
# For more details, please visit the documentation site here:
# https://team.ammeon.com/confluence/display/LITPExt/Landscape+Installation
#


# 
# Helper function for debugging purpose. 
# ----------------------------------------
# Reduces the clutter on the script's output while saving everything in 
# landscape.log file in the user's current directory. Can safely be removed 
# if not needed.

STEP=0
LOGDIR="logs"
if [ ! -d "$LOGDIR" ]; then
    mkdir $LOGDIR
fi
LOGFILE="${LOGDIR}/landscape_inventory.log"
if [ -f "${LOGFILE}" ]; then
    mod_date=$(date +%Y%m%d_%H%M%S -r "$LOGFILE")
    NEWLOG="${LOGFILE%.log}-${mod_date}.log"

    if [ -f "${NEWLOG}" ]; then  # in case ntp has reset time and log exists
        NEWLOG="${LOGFILE%.log}-${mod_date}_1.log"
    fi
    cp "$LOGFILE" "${NEWLOG}"
fi

> "$LOGFILE"
function litp() {
        STEP=$(( ${STEP} + 1 ))
        printf "Step %03d: litp %s\n" $STEP "$*" | tee -a "$LOGFILE"
        
        command litp "$@" 2>&1 | tee -a "$LOGFILE"
        if [ "${PIPESTATUS[0]}" -gt 0 ]; then
                exit 1;
        fi
}

# --------------------------------------------
# INVENTORY STARTS HERE
# --------------------------------------------

# ---------------------------------------------
# UPDATE NFS SERVER DETAILS
# ---------------------------------------------

# "SFS" driver is used for NAS storage device and "RHEL" for when an extra RHEL
# Linux node is used.
# password is only needed if ssh keys have not been setup up ( ie in case of SFS )
litp /inventory/deployment1/ms1/ms_node/sfs/export1 update share="%%export1_share%%" driver="%%export1_driver%%" user="%%export1_user%%" password="%%export1_password%%" storage_pool="%%export1_storage_pool%%" server="%%export1_IP%%" path="%%export1_path%%"

# update the shares with the password details, etc
litp /inventory/deployment1/ms1/ms_node/sfs/export_storadm update share="%%export_storadm_share%%" driver="%%export_storadm_driver%%" user="%%export_storadm_user%%" password="%%export_storadm_password%%" storage_pool="%%export_storadm_storage_pool%%" server="%%export_storadm_IP%%" path="%%export_storadm_path%%"
litp /inventory/deployment1/ms1/ms_node/sfs/export_storobs update share="%%export_storobs_path%%" driver="%%export_storobs_driver%%" user="%%export_storobs_user%%" password="%%export_storobs_password%%" storage_pool="%%export_storobs_storage_pool%%" server="%%export_storobs_IP%%" path="%%export_storobs_path%%"

litp /inventory/deployment1/cluster1/sc1/control_1/sfs/sfs_share_1 update share="%%export1_share%%" shared_size="%%export1_share_size%%"
litp /inventory/deployment1/cluster1/sc2/control_2/sfs/sfs_share_1 update share="%%export1_share%%" shared_size="%%export1_share_size%%"

litp /inventory/deployment1/ms1/ms_node/sfs_homedir/sfs_share_storadm update share="%%export_storadm_share%%" shared_size="%%export_storadm_share_size%%"
litp /inventory/deployment1/ms1/ms_node/sfs_homedir/sfs_share_storobs update share="%%export_storobs_path%%" shared_size="%%export_storobs_share_size%%"
#litp /inventory/deployment1/cluster1/sc1/control_1/sfs_homedir/sfs_share_storadm update share="%%export_storadm_share%%" shared_size="%%export_storadm_share_size%%"
#litp /inventory/deployment1/cluster1/sc1/control_1/sfs_homedir/sfs_share_storobs update share="%%export_storobs_path%%" shared_size="%%export_storobs_share_size%%"
#litp /inventory/deployment1/cluster1/sc2/control_2/sfs_homedir/sfs_share_storadm update share="%%export_storadm_share%%" shared_size="%%export_storadm_share_size%%"
#litp /inventory/deployment1/cluster1/sc2/control_2/sfs_homedir/sfs_share_storobs update share="%%export_storobs_path%%" shared_size="%%export_storobs_share_size%%"
# ---------------------------------------------
# CREATE AN IP ADDRESS POOL
# ---------------------------------------------

litp /inventory/deployment1/network create ip-address-pool

# Add available addresses to the network pool for each node. Order is important
# and is based on the ascending sort order of the objects' names
litp /inventory/deployment1/network/ip_ms1 create ip-address subnet=%%ip_ms1_subnetmask%% address=%%ip_ms1_address%% gateway=%%ip_ms1_gateway%%
litp /inventory/deployment1/network/ip_ms1 update vlan=834 # DL380 .28 workaround
litp /inventory/deployment1/network/ip_ms1 enable
litp /inventory/deployment1/ms1/ms_node/os/ip allocate

# Allocate an IP address to Service Group 1 Service instance 0
litp /inventory/deployment1/network/ip_sg1_si_0 create ip-address subnet=%%ip_sg1_si_0_subnetmask%% address=%%ip_sg1_si_0_address%% gateway=%%ip_sg1_si_0_gateway%%
litp /inventory/deployment1/network/ip_sg1_si_0 enable
litp /inventory/deployment1/cluster1/sg1/si_0/jee_container/instance/ip allocate

# Allocate an IP address to Service Group 1 Service instance 1
litp /inventory/deployment1/network/ip_sg1_si_1 create ip-address subnet=%%ip_sg1_si_1_subnetmask%% address=%%ip_sg1_si_1_address%% gateway=%%ip_sg1_si_1_gateway%%
litp /inventory/deployment1/network/ip_sg1_si_1 enable
litp /inventory/deployment1/cluster1/sg1/si_1/jee_container/instance/ip allocate

litp /inventory/deployment1/network/ip_node1 create ip-address subnet=%%ip_node1_subnetmask%% address=%%ip_node1_address%% gateway=%%ip_node1_gateway%%
litp /inventory/deployment1/network/ip_node1 enable
litp /inventory/deployment1/cluster1/sc1/control_1/os/ip allocate

litp /inventory/deployment1/network/ip_node2 create ip-address subnet=%%ip_node2_subnetmask%% address=%%ip_node2_address%% gateway=%%ip_node2_gateway%%
litp /inventory/deployment1/network/ip_node2 enable
litp /inventory/deployment1/cluster1/sc2/control_2/os/ip allocate

litp /inventory/deployment1/network/control_sfs create ip-address subnet=%%ip_control_sfs_subnetmask%% address=%%ip_control_sfs_address%% gateway=%%ip_control_sfs_gateway%%
litp /inventory/deployment1/network/control_sfs enable
litp /inventory/deployment1/sfs/control_sfs/os/ip allocate

# ---------------------------------------------
# CREATE A TIPC ADDRESS POOL
# ---------------------------------------------

litp /inventory/deployment1/tipc create tipc-address-pool netid="%%tipc_netid%%"


## ---------------------------------------------
## VCS updates
## ---------------------------------------------
litp /inventory/deployment1/cluster1/vcs_config update vcs_csgvip=%%vcs_config_vcs_csgvip%% vcs_csgnic="%%vcs_config_vcs_csgnic%%" vcs_lltlinklowpri1="%%vcs_config_vcs_lltlinklowpri1%%" vcs_lltlink2="%%vcs_config_vcs_lltlink2%%" vcs_lltlink1="%%vcs_config_vcs_lltlink1%%" vcs_csgnetmask="%%vcs_config_vcs_csgnetmask%%" vcs_clusterid="%%vcs_config_vcs_clusterid%%" vcs_gconetmask="%%vcs_config_vcs_gconetmask%%" vcs_gconic="%%vcs_config_vcs_gconic%%" vcs_gcovip="%%vcs_config_vcs_gcovip%%" gco="%%vcs_config_gco%%"


 
 
# This allocate call creates the neccessary VCS groups and resources
# cmw_cluster_config searches through the service groups for resources that cannot be controlled/monitored by CMW
litp /inventory/deployment1/cluster1/cmw_cluster_config allocate

# ---------------------------------------------
# ADD THE SAN STORAGE DEVICE FOR NODES
# ---------------------------------------------

#
# Double check that you have applied the correct information in all parameters
# This is the block device from which the nodes will boot from
#
litp /inventory/deployment1/sanBase create storage-pool-san-base storeName="%%sanBase_storeName%%" storeIPv4IP1=%%sanBase_storeIPv4IP1%% storeIPv4IP2=%%sanBase_storeIPv4IP2%% storeUser="%%sanBase_storeUser%%" storePassword="%%sanBase_storePassword%%" storeType="%%sanBase_storeType%%" storeLoginScope="%%sanBase_storeLoginScope%%" storeSiteId="%%sanBase_storeSiteId%%"
litp /inventory/deployment1/sanBase/san1 create storage-pool-san storeBlockDeviceDefaultSize="%%san1_storeBlockDeviceDefaultSize%%" storeBlockDeviceDefaultNamePrefix="%%san1_storeBlockDeviceDefaultNamePrefix%%" storePoolId="%%san1_storePoolId%%" poolModes="%%san1_poolModes%%"
# Create private data lun pool
#litp /inventory/deployment1/sanBase/san_pds create storage-pool-san storeBlockDeviceDefaultSize="%%san_pds_storeBlockDeviceDefaultSize%%" storeBlockDeviceDefaultNamePrefix="%%san_pds_storeBlockDeviceDefaultNamePrefix%%" storePoolId="%%san_pds_storePoolId%%" poolModes="%%san_pds_poolModes%%"
litp /inventory/deployment1/sanBase/appvg create storage-pool-san storeBlockDeviceDefaultSize="%%san_appvg_storeBlockDeviceDefaultSize%%" storeBlockDeviceDefaultNamePrefix="%%san_appvg_storeBlockDeviceDefaultNamePrefix%%" storePoolId="%%san_appvg_storePoolId%%" poolModes="%%san_appvg_poolModes%%"


# ---------------------------------------------
# ADD THE PHYSICAL SERVERS
# ---------------------------------------------

#
# In this example, all servers are blades inside an HPC7000 enclosure
# All information about the blades is gathered from quering the enclosure(s)
#

# Adding an enclosure providing also the info needed to connect and login to it
litp /inventory/deployment1/systems create generic-system-pool
litp /inventory/deployment1/systems/enclosure create hp-c7000-enclosure OAIP1=%%enclosure1_OAIP1%% OAIP2=%%enclosure1_OAIP2%% username=%%enclosure1_username%% password=%%enclosure1_password%%
#litp /inventory/deployment1/systems/enclosure2 create hp-c7000-enclosure OAIP1=%%enclosure2_OAIP1%% OAIP2=%%enclosure2_OAIP2%% username=%%enclosure2_username%% password=%%enclosure2_password%%

#
# Run a discover on the enclosure, all blades will be created as objects in
# memory named after the serial numbers of the blades. Those will be available
# for further configuration and for utilization. MAC addresses will be
# automatically configured.
#
litp /inventory/deployment1/systems/enclosure discover
#litp /inventory/deployment1/systems/enclosure2 discover

# Updating each blades iLO information with login info and enabling the systems
# for use in the cluster. The order of enabling is important, blades will be
# allocated in this order [MS-1 SC-1 SC-2 PL-3 ... ]. 
#

# We enable the blade for MS-1 early to secure that it is allocated for that
# role. We provide the false login info for iLO to avoid being reboot by
# landscape.
litp /inventory/deployment1/systems/dl380 create generic-system macaddress="%%dl380_macaddress%%" hostname="%%dl380_hostname%%" domain=%%dl380_domain%%
litp /inventory/deployment1/systems/dl380 enable

# The rest of the servers
litp /inventory/deployment1/systems/enclosure/%%blade1_serial%% update domain=%%blade1_domain%% iloUsername=%%blade1_iloUsername%% iloPassword=%%blade1_iloPassword%%
litp /inventory/deployment1/systems/enclosure/%%blade2_serial%% update domain=%%blade2_domain%% iloUsername=%%blade2_iloUsername%% iloPassword=%%blade2_iloPassword%%

# ---------------------------------------------
# ADD AN NTP SERVER  
# ---------------------------------------------

# Systems updating time directly from ntp server
litp /inventory/deployment1/ntp_1 update ipaddress="%%ntp_1_ipaddress%%"

# ------------------------------------------------------------
# SET THIS PROPERTY FOR ALL SYSTEMS NOT TO BE ADDED TO COBBLER
# ------------------------------------------------------------
litp /inventory/deployment1/ms1 update add_to_cobbler="False"
litp /inventory/deployment1/sfs update add_to_cobbler="False"

# Update the user's passwords
# The user's passwords must be encrypted, the encryption method is Python's 2.6.6
# crypt function. The following is an example for encrypting the phrase 'passw0rd'
#
# [cmd_prompt]$ python
# Python 2.6.6 (r266:84292, May 20 2011, 16:42:11) 
# [GCC 4.4.5 20110214 (Red Hat 4.4.5-6)] on linux2
# Type "help", "copyright", "credits" or "license" for more information.
# >>> import crypt
# >>> crypt.crypt("passw0rd")
# '$6$VbIEnv1XppQpNHel$/ikRQIa5i/cNJR2BYucNkTjHmO/HBzHdvDbsXa7fprXILrGYa.xMOPI9b.y5HrfqWHfVyfXK7AffI9DrkUBWJ.'
#
# Symbol '$' is a shell metacharacter and needs to be "escaped" with '\\\'
#
litp /inventory/deployment1/ms1/ms_node/users/litp_admin update password=%%ms1_users_litp_admin_password%%
litp /inventory/deployment1/ms1/ms_node/users/litp_user update password=%%ms1_users_litp_user_password%%
litp /inventory/deployment1/ms1/ms_node/users/litp_jboss update password=%%ms1_users_litp_user_jboss_password%%
litp /inventory/deployment1/cluster1/sc1/control_1/users/litp_admin update password=%%sc1_users_litp_admin_password%%
litp /inventory/deployment1/cluster1/sc1/control_1/users/litp_user update password=%%sc1_users_litp_user_password%%
litp /inventory/deployment1/cluster1/sc1/control_1/users/litp_jboss update password=%%sc1_users_litp_jboss_password%%
litp /inventory/deployment1/cluster1/sc2/control_2/users/litp_admin update password=%%sc2_users_litp_admin_password%%
litp /inventory/deployment1/cluster1/sc2/control_2/users/litp_user update password=%%sc2_users_litp_user_password%%
litp /inventory/deployment1/cluster1/sc2/control_2/users/litp_jboss update password=%%sc2_users_litp_jboss_password%%

# ---------------------------------------------
# CONFIGURE & ALLOCATE THE RESOURCES
# ---------------------------------------------

#
# Set MySQL Password
#
litp /inventory/deployment1/ms1/ms_node/mysqlserver/config update password="%%mysqlserver_config_password%%"

# MS to allocate first and "secure" the blade hw for this node.
litp /inventory/deployment1/ms1 allocate
litp /inventory/deployment1/ms1/ms_node/os/system update hostname="ms1"

# This is the SFS server 10.44.86.31
litp /inventory/deployment1/systems/sfsmachine create generic-system macaddress="%%sfsmachine_macaddress%%" hostname="%%sfsmachine_hostname%%" domain=%%sfsmachine_domain%%
litp /inventory/deployment1/systems/sfsmachine enable
litp /inventory/deployment1/sfs allocate
litp /inventory/deployment1/sfs/control_sfs/os/system update hostname="%%sfsmachine_hostname%%"

# Allocate remmaining blades
# LITP-1808 workaround: enable blade used for SC-1 and allocate immediately
litp /inventory/deployment1/systems/enclosure/%%blade1_serial%% enable
litp /inventory/deployment1/cluster1/sc1 allocate

# LITP-1808 workaround: Enable blade used for SC-2 and allocate immediately
litp /inventory/deployment1/systems/enclosure/%%blade2_serial%% enable
litp /inventory/deployment1/cluster1/sc2 allocate

litp /inventory/deployment1 allocate

# Updating IP Addresses. Workaround (solved?) Needless after workaround in inmediate allocate after ip created in pools.
#litp /inventory/deployment1/ms1/ms_node/os/ip update address="10.44.86.28"
#litp /inventory/deployment1/cluster1/sc1/control_1/os/ip update address="10.44.86.8"
#litp /inventory/deployment1/cluster1/sc2/control_2/os/ip update address="10.44.86.47"

# Updating hostnames of the systems. Workaround
litp /inventory/deployment1/cluster1/sc1/control_1/os/system update hostname="SC-1"  systemname="deployment1_cluster1_sc1"
litp /inventory/deployment1/cluster1/sc2/control_2/os/system update hostname="SC-2"  systemname="deployment1_cluster1_sc2"

litp /inventory/deployment1/sfs/control_sfs/os/system update hostname="%%sfsmachine_hostname%%" systemname="%%sfsmachine_systemname%%"

# Update kiskstart information. Convention for kickstart filenames is node's 
# hostname with a "ks" extension
litp /inventory/deployment1/cluster1/sc1/control_1/os/ks update ksname="SC-1.ks" path=/var/lib/cobbler/kickstarts
litp /inventory/deployment1/cluster1/sc1/control_1/os/ks/kspartition update boot_block_device_id=0 pv_block_device_id=0
litp /inventory/deployment1/cluster1/sc2/control_2/os/ks update ksname="SC-2.ks" path=/var/lib/cobbler/kickstarts
litp /inventory/deployment1/cluster1/sc2/control_2/os/ks/kspartition update boot_block_device_id=0 pv_block_device_id=0

# Allocate a block device for each node

litp /inventory/deployment1/cluster1/sc1/control_1/os/mpather create multipather
litp /inventory/deployment1/cluster1/sc1/control_1/os/boot_blockdevice create block-device-san pool="%%sc1_boot_blockdevice_pool%%" mode="%%sc1_boot_blockdevice_mode%%" size="%%sc1_boot_blockdevice_size%%" bladePowerManaged="%%sc1_boot_blockdevice_bladePowerManaged%%"
litp /inventory/deployment1/cluster1/sc1/control_1/os/boot_blockdevice/mpath create mpath device_path="%%sc1_boot_blockdevice_mpath%%"

litp /inventory/deployment1/cluster1/sc2/control_2/os/mpather create multipather
litp /inventory/deployment1/cluster1/sc2/control_2/os/boot_blockdevice create block-device-san pool="%%sc2_boot_blockdevice_pool%%" mode="%%sc2_boot_blockdevice_mode%%" size="%%sc2_boot_blockdevice_size%%" bladePowerManaged="%%sc2_boot_blockdevice_bladePowerManaged%%"
litp /inventory/deployment1/cluster1/sc2/control_2/os/boot_blockdevice/mpath create mpath device_path="%%sc2_boot_blockdevice_mpath%%"


# Allocate a private block device for each node
#litp /inventory/deployment1/cluster1/sc1/control_1/os/data_blockdevice create block-device-san pool="san_pds" mode="private_data" size="100M" bladePowerManaged=False
#litp /inventory/deployment1/cluster1/sc1/control_1/os/data_blockdevice/mpath create mpath device_path="/dev/mapper/data_device"
#litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm create lvm
#litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm/pv1 create phys-vol device=/inventory/deployment1/cluster1/sc1/control_1/os/data_blockdevice
#litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm/sg2_si_0_vcsgrp_comp_vcsvg_mount create vol-grp pv="pv1"
#litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm/sg2_si_0_vcsgrp_comp_vcslv_mount create log-vol vg="sg2_si_0_vcsgrp_comp_vcsvg_mount" size="80M"
#litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm/fs1 create file-sys lv="sg2_si_0_vcsgrp_comp_vcslv_mount"

#litp /inventory/deployment1/cluster1/sc2/control_2/os/data_blockdevice create block-device-san pool="san_pds" mode="private_data" size="100M" bladePowerManaged=False
#litp /inventory/deployment1/cluster1/sc2/control_2/os/data_blockdevice/mpath create mpath device_path="/dev/mapper/data_device"
#litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm create lvm
#litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm/pv1 create phys-vol device=/inventory/deployment1/cluster1/sc1/control_1/os/data_blockdevice
#litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm/sg2_si_0_vcsgrp_comp_vcsvg_mount create vol-grp pv="pv1"
#litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm/sg2_si_0_vcsgrp_comp_vcslv_mount create log-vol vg="sg2_si_0_vcsgrp_comp_vcsvg_mount" size="80M"
#litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm/fs1 create file-sys lv="sg2_si_0_vcsgrp_comp_vcslv_mount"

litp /inventory/deployment1/cluster1/sc1/control_1/os/data_blockdevice_app create block-device-san pool="%%sc1_databd_appvg_pool%%" mode="%%sc1_databd_appvg_mode%%" size="%%sc1_databd_appvg_size%%" bladePowerManaged=%%sc1_databd_appvg_bladePowerManaged%%
litp /inventory/deployment1/cluster1/sc1/control_1/os/data_blockdevice_app/mpath_app create mpath device_path="%%sc1_databd_appvg_device_path%%"

litp /inventory/deployment1/cluster1/sc1/control_1/os/data_blockdevice_app allocate

litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm_app create lvm
litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm_app/pv_app create phys-vol device=/inventory/deployment1/cluster1/sc1/control_1/os/data_blockdevice_app
litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm_app/vg_app create vol-grp pv="%%sc1_vg_app_volgrp_pv%%"
litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm_app/lv_app create log-vol vg="%%sc1_vg_app_logvol_vg%%" size="%%sc1_vg_app_logvol_size%%"
litp /inventory/deployment1/cluster1/sc1/control_1/os/lvm_app/fs_app create file-sys lv="%%sc1_vg_app_filesys_lv%%"

litp /inventory/deployment1/cluster1/sc2/control_2/os/data_blockdevice_app create block-device-san pool="%%sc2_databd_appvg_pool%%" mode="%%sc2_databd_appvg_mode%%" size="%%sc2_databd_appvg_size%%" bladePowerManaged=%%sc2_databd_appvg_bladePowerManaged%%
litp /inventory/deployment1/cluster1/sc2/control_2/os/data_blockdevice_app/mpath_app create mpath device_path="%%sc2_databd_appvg_device_path%%"

litp /inventory/deployment1/cluster1/sc2/control_2/os/data_blockdevice_app allocate

litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm_app create lvm
litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm_app/pv_app create phys-vol device=/inventory/deployment1/cluster1/sc2/control_2/os/data_blockdevice_app
litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm_app/vg_app create vol-grp pv="%%sc2_vg_app_volgrp_pv%%"
litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm_app/lv_app create log-vol vg="%%sc2_vg_app_logvol_vg%%" size="%%sc2_vg_app_logvol_size%%"
litp /inventory/deployment1/cluster1/sc2/control_2/os/lvm_app/fs_app create file-sys lv="%%sc2_vg_app_filesys_lv%%"

#litp /inventory/ configure

#litp /cfgmgr apply scope=/inventory

# Update the verify user to root. Workaround, user litp_verify doesn't exist yet
litp /inventory/deployment1/ms1 update verify_user="root"
litp /inventory/deployment1/cluster1/sc1 update verify_user="root"
litp /inventory/deployment1/cluster1/sc2 update verify_user="root"

####### Start of new networking ###################################

#Turn on new framework on the MS and the peer servers SC1 and SC2
#litp /inventory/deployment1/ms1/ms_node/os update topo_framework='on'
#litp /inventory/deployment1/cluster1/sc1/control_1/os update topo_framework='on'
#litp /inventory/deployment1/cluster1/sc2/control_2/os update topo_framework='on'

#Creation of digraph

litp /inventory/deployment1 load /opt/ericsson/nms/litp/bin/samples/netgraphs/netgraph_1_bond0_MN.xml
#litp /inventory/deployment1/ms1/ load /opt/ericsson/nms/litp/bin/samples/netgraphs/netgraph_1_bond0_MS_DL380.xml

#litp /inventory/deployment1/ms1/ms_node/os/system/linuxnetconfig create linux-net-conf
litp /inventory/deployment1/cluster1/sc1/control_1/os/system/linuxnetconfig create linux-net-conf
litp /inventory/deployment1/cluster1/sc2/control_2/os/system/linuxnetconfig create linux-net-conf

#create pools
litp /inventory/deployment1/ipv4_pool_traffic create ip-address-pool subnet=1.2.3.0/24 start=1.2.3.1 end=1.2.3.3

#litp /inventory/deployment1/ipv6_pool_mgmt create ipv6-address-pool subnet=fec0::100/64 start=fec0::101 end=fec0::103

#litp /inventory/deployment1/ipv6_pool_traffic create ipv6-address-pool subnet=fe80::100/64 start=fe80::104 end=fe80::106

#Create ip for DL380 for VLAN835
#litp /inventory/deployment1/ms1/ip_ms1_b create ip-address subnet=10.44.86.0/24 address=10.44.86.111 gateway=10.44.86.65 net_name=mgmtb

#Create an IPv4 object under each node and give it a network name of "traffic"
#litp /inventory/deployment1/ms1/ms_node/os/ip_traffic create ip-address pool=ipv4_pool_traffic net_name=traffic
litp /inventory/deployment1/cluster1/sc1/control_1/os/ip_traffic create ip-address pool=ipv4_pool_traffic net_name=traffic
litp /inventory/deployment1/cluster1/sc2/control_2/os/ip_traffic create ip-address pool=ipv4_pool_traffic net_name=traffic

#Create an IPv6 object under each node and give it a network name of "mgmt"
#litp /inventory/deployment1/ms1/ms_node/os/ipv6_mgmt create ipv6-address pool=ipv6_pool_mgmt net_name=mgmt
#litp /inventory/deployment1/cluster1/sc1/control_1/os/ipv6_mgmt create ipv6-address pool=ipv6_pool_mgmt net_name=mgmt
#litp /inventory/deployment1/cluster1/sc2/control_2/os/ipv6_mgmt create ipv6-address pool=ipv6_pool_mgmt net_name=mgmt

#Create another  IPv6 object under each node and give it a network name of "traffic"
#litp /inventory/deployment1/ms1/ms_node/os/ipv6_traffic create ipv6-address pool=ipv6_pool_traffic net_name=traffic
#litp /inventory/deployment1/cluster1/sc1/control_1/os/ipv6_traffic create ipv6-address pool=ipv6_pool_traffic net_name=traffic
#litp /inventory/deployment1/cluster1/sc2/control_2/os/ipv6_traffic create ipv6-address pool=ipv6_pool_traffic net_name=traffic

###### End of new networking #####################

# Allocate the complete site
litp /inventory/deployment1 allocate

# --------------------------------------
# APPLY CONFIGURATION TO PUPPET
# --------------------------------------

# Configure BIOS settings on all PSs.
# Currently fails. BUG LITP-856
# The next lines do not work in G8 environment, they are not destructive.
# They should work in G6 environment 
litp /inventory/deployment1/cluster1/sc1/control_1/os/system/bios update powerOffAfterConfigure=True
litp /inventory/deployment1/cluster1/sc2/control_2/os/system/bios update powerOffAfterConfigure=True

litp /inventory/deployment1/cluster1/sc1/control_1/os/system configurebios
litp /inventory/deployment1/cluster1/sc2/control_2/os/system configurebios

# Update VCS configuration
litp /inventory/deployment1/cluster1/sg1/si_0/vcsgrp_jee_container/vcsip_ip update device="bond0"
litp /inventory/deployment1/cluster1/sg1/si_0/vcsgrp_jee_container/vcsnic_ip update device="bond0"
litp /inventory/deployment1/cluster1/sg1/si_1/vcsgrp_jee_container/vcsip_ip update device="bond0"
litp /inventory/deployment1/cluster1/sg1/si_1/vcsgrp_jee_container/vcsnic_ip update device="bond0"

# create the sfssetup to run on the ms_node ( could be any other node with the sfs_home dirs mounted )
litp /inventory/deployment1/ms1/ms_node/os/sfssetup create sfs-setup-keys server=%%sfssetup_server%% username=%%sfssetup_username%% password=%%sfssetup_password%%

# This is an intermediate step before applying the configuration to puppet
litp /inventory/deployment1 configure
litp /inventory/deployment1/cluster1/cmw_cluster_config configure

# --------------------------------------
# VALIDATE INVENTORY CONFIGURATION
# --------------------------------------

litp /inventory validate

# --------------------------------------
# APPLY CONFIGURATION TO PUPPET
# --------------------------------------

# Configuration's Manager (Puppet) manifests for the inventory will be created
# after this
litp /cfgmgr apply scope=/inventory

# Campaign Generation Steps
litp /inventory/deployment1/cluster1/cmw_cluster_config/etf_generator generate_etfs
litp /inventory/deployment1/cluster1/cmw_cluster_config/etf_generator verify
litp /inventory/deployment1/cluster1/cmw_cluster_config/campaign_generator generate


# (check for puppet errors -> "grep puppet /var/log/messages")
# (use "service puppet restart" to force configuration now)

# --------------------------------------------
# INVENTORY ENDS HERE
# --------------------------------------------

echo "Inventory addition has completed"
echo "Please wait for puppet to configure cobbler. This should take about 3 minutes"

exit 0
