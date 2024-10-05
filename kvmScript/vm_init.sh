#!/bin/bash

# VM specifications
NUM_VMS=3
VM_NAME_PREFIX="vm"
CPU=4
RAM=4096 # 4 GB in MB
DISK_SIZE=20G # Disk size for each VM
IMG_PATH="/var/lib/libvirt/images" # Path to store VM disk images
ISO_PATH="/home/cn47/Downloads/Rocky-9.4-x86_64-minimal.iso" # Path to the Ubuntu ISO (or any other OS image)

# Network settings
PRIVATE_NET_NAME="private_net"
PRIVATE_NET_XML="/tmp/private_net.xml"
WLAN_INTERFACE="wlp0s20f3"  # Replace with your actual wireless interface

# Static IPs for VMs in the private network
PRIVATE_NET_STATIC_IPS=("10.2.0.1" "10.2.0.2" "10.2.0.3")
PRIVATE_NET_GATEWAY="10.2.0.254"
PRIVATE_NET_MASK="255.255.255.0"

# Base MAC address for VMs (only the last byte will change)
BASE_MAC="52:54:00:12:34:"

# Function to enable IP forwarding and NAT
enable_nat() {
  echo "Enabling NAT on interface $WLAN_INTERFACE..."

  # Enable IP forwarding
  sudo sysctl -w net.ipv4.ip_forward=1

  # Setup NAT using iptables
  sudo iptables -t nat -A POSTROUTING -s 10.2.0.0/24 -o "$WLAN_INTERFACE" -j MASQUERADE
}

# Function to create a private network with DHCP reservation
create_private_network() {
  echo "Creating private network $PRIVATE_NET_NAME..."

  if ! virsh net-list --all | grep -q "$PRIVATE_NET_NAME"; then
    cat > "$PRIVATE_NET_XML" <<EOL
<network>
  <name>$PRIVATE_NET_NAME</name>
  <forward mode="nat"/>
  <bridge name="virbr1" stp="on" delay="0"/>
  <ip address="$PRIVATE_NET_GATEWAY" netmask="$PRIVATE_NET_MASK">
    <dhcp>
      <range start="10.2.0.100" end="10.2.0.200"/>
EOL

    # Add static IP reservations for each VM
    for i in $(seq 0 $(($NUM_VMS-1))); do
      MAC_ADDRESS="${BASE_MAC}$(printf "%02x" $i)"
      cat >> "$PRIVATE_NET_XML" <<EOL
      <host mac="$MAC_ADDRESS" name="$VM_NAME_PREFIX$((i+1))" ip="${PRIVATE_NET_STATIC_IPS[$i]}"/>
EOL
    done

    cat >> "$PRIVATE_NET_XML" <<EOL
    </dhcp>
  </ip>
</network>
EOL

    sudo virsh net-define "$PRIVATE_NET_XML"
    sudo virsh net-autostart "$PRIVATE_NET_NAME"
    sudo virsh net-start "$PRIVATE_NET_NAME"
  else
    echo "Private network $PRIVATE_NET_NAME already exists."
  fi
}

# Function to create a VM
create_vm() {
  VM_NAME="$VM_NAME_PREFIX$1"
  VM_DISK="$IMG_PATH/$VM_NAME.qcow2"
  MAC_ADDRESS="${BASE_MAC}$(printf "%02x" $(($1-1)))"
  
  echo "Creating disk image for $VM_NAME..."
  qemu-img create -f qcow2 "$VM_DISK" $DISK_SIZE

  echo "Creating VM: $VM_NAME with $CPU CPUs, $RAM MB RAM, $DISK_SIZE disk..."
  virt-install \
    --name "$VM_NAME" \
    --vcpus "$CPU" \
    --memory "$RAM" \
    --disk path="$VM_DISK",format=qcow2 \
    --cdrom "$ISO_PATH" \
    --network network="$PRIVATE_NET_NAME",model=virtio,mac="$MAC_ADDRESS" \
    --os-type linux \
    --os-variant "rocky9" \
    --graphics vnc,password=12345678,listen=0.0.0.0 \
    --video virtio

  echo "VM $VM_NAME created successfully!"
}

# Main script
echo "Setting up network configurations..."
enable_nat
create_private_network

echo "Creating $NUM_VMS VMs..."

# Loop to create the required number of VMs
for i in $(seq 1 $NUM_VMS); do
  create_vm "$i"
done

echo "All VMs created successfully!"



#################################### IP- FORWARDING #############################################
# To access the virtual machines (VMs) created by the script from a device on the host's 
# network, you need to ensure that the VMs are reachable from the host network.
# Since the script creates VMs on a private virtual network using NAT (Network Address Translation),
# by default, VMs are not directly accessible from devices on the host's network.
# However, there are a few ways you can make the VMs accessible externally:


# Option 1: Port Forwarding with iptables

# You can set up port forwarding on the host machine using iptables to forward traffic from the 
# host's IP address and port to the corresponding VM.

# Steps:

# Find the VM's IP Address: The script assigns static IPs to the VMs (e.g., 10.2.0.1, 10.2.0.2, etc.).
# Forward Ports: Use iptables to forward a specific port (e.g., SSH on port 22) 
# from the host's network interface to the VM's private IP address.

# For example, to forward port 2222 on the host machine to SSH (port 22)
# on 10.2.0.1 (VM1), you can run the following commands:
# bash
# # Forward traffic from host port 2222 to VM 10.2.0.1 port 22
# sudo iptables -t nat -A PREROUTING -p tcp -d <host_ip> --dport 2222 -j DNAT --to-destination 10.2.0.1:22
# sudo iptables -A FORWARD -p tcp -d 10.2.0.1 --dport 22 -j ACCEPT

# To access the VM from another device on the host network:
# bash
# ssh user@<host_ip> -p 2222
# Repeat the process for other VMs by forwarding different ports (e.g., 2223 for VM2, 2224 for VM3).

# Save the iptables rules to make them persistent across reboots:
# bash
# sudo iptables-save > /etc/iptables/rules.v4

#####################################################################################################