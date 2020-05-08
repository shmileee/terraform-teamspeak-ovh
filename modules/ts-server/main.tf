data "openstack_networking_network_v2" "public" {
  name = "Ext-Net"
}

resource "openstack_networking_port_v2" "public" {
  count          = var.instances_count
  name           = "${var.name}_${count.index}"
  network_id     = data.openstack_networking_network_v2.public.id
  admin_state_up = "true"
}

data "http" "myip" {
  url = "https://api.ipify.org"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = var.name
  public_key = file(var.ssh_public_key)
}

data "template_file" "setup" {
  template = <<SETUP
#!/bin/bash

apt_wait () {
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
    sleep 1
  done
  while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
    while sudo fuser /var/log/unattended-upgrades/unattended-upgrades.log >/dev/null 2>&1 ; do
      sleep 1
    done
  fi
}

# install softwares & depencencies
apt update -y && apt install -y ufw python3 python3-pip && apt_wait
pip3 install docker docker-compose

# setup firewall
ufw default deny
ufw allow in on ens3 proto tcp from 0.0.0.0/0 to 0.0.0.0/0 port 9987
ufw allow in on ens3 proto tcp from 0.0.0.0/0 to 0.0.0.0/0 port 10077
ufw allow in on ens3 proto tcp from 0.0.0.0/0 to 0.0.0.0/0 port 30033
ufw allow in on ens3 proto tcp from ${trimspace(data.http.myip.body)}/32 to 0.0.0.0/0 port 22
ufw enable

# setup systemd services
systemctl enable ufw
systemctl restart ufw
SETUP
}

data "template_file" "userdata" {
  template = <<CLOUDCONFIG
#cloud-config

write_files:
  - path: /tmp/setup/run.sh
    permissions: '0755'
    content: |
      ${indent(6, data.template_file.setup.rendered)}
  - path: /etc/systemd/network/30-ens3.network
    permissions: '0644'
    content: |
      [Match]
      Name=ens3
      [Network]
      DHCP=ipv4

runcmd:
   - /tmp/setup/run.sh
CLOUDCONFIG
}

resource "openstack_compute_instance_v2" "nodes" {
  count           = var.instances_count
  name            = "${var.name}_${count.index}"
  image_name      = "Ubuntu 18.04"
  flavor_name     = var.flavor_name
  key_pair        = openstack_compute_keypair_v2.keypair.name
  user_data       = data.template_file.userdata.rendered
  security_groups = ["default"]

  network {
    name = "Ext-Net"
  }

  metadata = {
    teamspeak3_servers = ""
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.ssh_user
      timeout     = "3m"
      private_key = file(var.ssh_private_key)
      host        = self.access_ip_v4
    }
    inline = [
      "cloud-init status --wait"
    ]
  }
}
