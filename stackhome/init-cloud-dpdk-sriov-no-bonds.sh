#!/bin/sh

source /home/stack/overcloudrc
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0

#openstack flavor create --vcpus 8 --ram 4096 --disk 40 m1.nano
#openstack flavor set m1.nano --property hw:mem_page_size=large

openstack flavor create  m1.dpdk_vnf --ram 4096 --disk 150 --vcpus 8
openstack flavor set --property hw:cpu_policy=dedicated --property hw:mem_page_size=large --property hw:numa_nodes=1 --property hw:numa_mempolicy=preferred --property  hw:numa_cpus.1=0,1,2,3,4,5,6,7 --property hw:numa_mem.1=4096 m1.dpdk_vnf


neutron net-create --provider:network_type vlan --provider:segmentation_id 100 --provider:physical_network datacentre public --router:external
neutron subnet-create --name public --allocation-pool start=10.19.108.150,end=10.19.108.200  --dns-nameserver 10.19.5.19  --gateway 10.19.108.254 --disable-dhcp public 10.19.108.0/24

#neutron net-create --provider:segmentation_id 4072 --provider:physical_network datacentre private --router:external
#neutron subnet-create --name private --allocation-pool start=192.168.108.150,end=192.168.108.200  --dns-nameserver 10.19.5.19  --gateway 192.168.108.254 


#openstack network create --external --provider-network-type vlan --provider-physical-network datacentre --provider-segment 100 external
#openstack subnet create external --network external --dhcp --allocation-pool start=10.19.108.150,end=10.19.108.250 --gateway 10.19.108.254 --subnet-range 10.19.108.0/24 --dns-nameserver 10.19.5.19 


neutron net-create dpdk0 --provider:network_type vlan --provider:segmentation_id 4071 --provider:physical_network tenant  #(name given in Neutron bridgeMappings)
neutron subnet-create --name dpdk0 --allocation-pool start=20.35.185.49,end=20.35.185.61 --dns-nameserver 8.8.8.8 --gateway 20.35.185.62 dpdk0 20.35.185.48/28
dpdk0_net=$(neutron net-list | awk ' /dpdk0/ {print $2;}')

# Create router, set gateway and add interfaces to the router
openstack router create router0
neutron router-gateway-set router0 public
neutron router-interface-add router0 dpdk0
#nova boot --flavor m1.nano --nic net-id=$dpdk0_net --image rhel --key-name test  dpdk0


function get_image() {
  local url=$1
  local fname=$(basename $1)
  local image_name=$2
  
  if [ ! -f ./$fname ] 
  then
    wget $url 
  fi
  openstack image create --disk-format qcow2 --file ./$fname $image_name
#  rm ./$fname
}

#openstack network create --external --provider-network-type vlan --provider-physical-network dpdk --provider-segment 4075 tenant
#openstack subnet create tenant-subnet --network tenant --dhcp --allocation-pool start=192.1.0.150,end=192.1.0.200 --gateway 192.1.0.254 --subnet-range 192.1.0.0/24 --dns-nameserver 10.19.5.19 

#openstack router create tenant-router
#openstack router add subnet tenant-subnet tenant
#neutron router-gateway-set external external 


openstack floating ip create public
openstack floating ip create public
openstack floating ip create public
openstack floating ip create public
openstack floating ip create public
openstack floating ip create public
openstack floating ip create public

openstack keypair create --public-key /home/stack/.ssh/id_rsa.pub undercloud-stack

openstack security group create all-access
openstack security group rule create --ingress --protocol icmp --src-ip 0.0.0.0/0 all-access
openstack security group rule create --ingress --protocol tcp --src-ip 0.0.0.0/0 all-access
openstack security group rule create --ingress --protocol udp --src-ip 0.0.0.0/0 all-access


get_image https://download.fedoraproject.org/pub/fedora/linux/releases/25/CloudImages/x86_64/images/Fedora-Cloud-Base-25-1.3.x86_64.qcow2 fedora-25 Fedora-25
# get_image http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1503.qcow2c centos-7-1503
get_image http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img cirros-0.3.4
get_image http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2 centos-password


#----Network for SRIOV node----

#openstack network create default
#openstack subnet create default --network default --gateway 172.20.1.1 --subnet-range 172.20.0.0/16
#openstack router add subnet router0 default

neutron net-create --provider:network_type vlan --provider:physical_network tenant --provider:segmentation_id 4072 sriov1
net_id=$(neutron net-list | grep sriov1 | awk '{print $2}')
neutron subnet-create $net_id --allocation_pool start=172.21.0.2,end=172.21.1.0 --name sriov1-sub 172.21.0.0/16
sub_id=$(neutron subnet-list | grep sriov1-sub | awk '{print $2}')
neutron port-create --name sriov1-port --fixed-ip subnet_id=$sub_id,ip_address=172.21.0.10 --vnic-type direct $net_id

#openstack flavor create --ram 512 --disk 1 --vcpus 1 --public cirros.1
#openstack flavor create --ram 1024 --disk 1 --vcpus 1 --public small.1
#openstack flavor create --ram 2048 --disk 10 --vcpus 2 --public medium.1
openstack flavor create --ram 4096 --disk 20 --vcpus 4 --public large.1


