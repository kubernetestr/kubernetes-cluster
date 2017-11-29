# Vagrant kubernetes cluster

A HA kubernetes cluster to be run with Vagrant.


## Setup
  * Create a new virtual network with ip range `10.240.0.0/24`.
    * For Windows, see [here](https://superuser.com/questions/339465/creating-a-virtual-nic-on-windows-7).
    * For Linux, see [here](https://www.linux.com/learn/intro-to-linux/2017/5/creating-virtual-machines-kvm-part-2-networking).
  * run `init.sh` to generate CA.
  * `vagrant up`.
