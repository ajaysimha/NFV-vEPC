openstack overcloud deploy \
--templates  \
-e /home/stack/templates/ips-from-pool-all.yaml \
-e /home/stack/templates/network-isolation.yaml \
-e /home/stack/templates/network-environment.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-ovs-dpdk.yaml
