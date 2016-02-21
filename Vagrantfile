# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
disk = './secondDisk.vdi'
Vagrant.configure(2) do |config|
  config.vm.define "zfs" do |zfs|
    zfs.vm.box = "ubuntu/trusty64"
    zfs.vm.hostname = "zfs"

    zfs.vm.network :private_network, ip: "192.168.202.201"

    zfs.vm.provider "virtualbox" do |vb|
      unless File.exist?(disk)
        vb.customize ['createhd', '--filename', disk, '--variant', 'Fixed', '--size', 10 * 1024]
      end
      vb.memory = "1024"
      vb.customize ['storageattach', :id,  '--storagectl', 'SATAController', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]
    end
    zfs.vm.provision :shell, path: "provision.sh", keep_color: "true"
  end
  config.vm.define "client" do |client|
    client.vm.box = "ubuntu/trusty64"
    client.vm.hostname = "client"

    client.vm.network :private_network, ip: "192.168.202.202"
    client.vm.provision :shell, inline: "sudo apt-get update && sudo apt-get -y install open-iscsi"
  end
end
