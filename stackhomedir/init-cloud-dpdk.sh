#!/bin/sh

source /home/stack/overcloudrc
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0

openstack flavor create --vcpus 6 --ram 4096 --disk 40 m1.nano
openstack flavor set m1.nano --property hw:mem_page_size=large

neutron net-create --provider:network_type vlan --provider:segmentation_id 100 --provider:physical_network datacentre public --router:external
neutron subnet-create --name public --allocation-pool start=10.19.108.150,end=10.19.108.200  --dns-nameserver 10.19.5.19  --gateway 10.19.108.254 --disable-dhcp public 10.19.108.0/24

#neutron net-create --provider:segmentation_id 4072 --provider:physical_network datacentre private --router:external
#neutron subnet-create --name private --allocation-pool start=192.168.108.150,end=192.168.108.200  --dns-nameserver 10.19.5.19  --gateway 192.168.108.254 


#openstack network create --external --provider-network-type vlan --provider-physical-network datacentre --provider-segment 100 external
#openstack subnet create external --network external --dhcp --allocation-pool start=10.19.108.150,end=10.19.108.250 --gateway 10.19.108.254 --subnet-range 10.19.108.0/24 --dns-nameserver 10.19.5.19 


neutron net-create dpdk0 --provider:network_type vlan --provider:segmentation_id 4071 --provider:physical_network dpdk  #(name given in Neutron bridgeMappings)
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
get_image http://download.cirros-cloud.net/0.3.4/CentOS-7-x86_64-GenericCloud.qcow2 centos-password
