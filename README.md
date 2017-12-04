# Vagrant kubernetes cluster

A HA kubernetes cluster to be run with Vagrant.


## Setup
  * Create a new virtual network with ip range `10.240.0.0/24`.
    * For Windows, see [here](https://superuser.com/questions/339465/creating-a-virtual-nic-on-windows-7).
    * For Linux, see [here](https://www.linux.com/learn/intro-to-linux/2017/5/creating-virtual-machines-kvm-part-2-networking).
  * run `init.sh` to generate CA.
  * `vagrant up`.

## Pod Network
To ping pods within pods running on different nodes, run below commands on the host machine:
  * *nix:
    - route add -net 10.200.1.0 netmask 255.255.255.0 gw 10.240.0.31 
    - route add -net 10.200.2.0 netmask 255.255.255.0 gw 10.240.0.32
    - ...
  * Windows:
    - route add 10.200.1.0 mask 255.255.255.0 10.240.0.31 metric 325
    - route add 10.200.2.0 mask 255.255.255.0 10.240.0.32 metric 325
    - ...
