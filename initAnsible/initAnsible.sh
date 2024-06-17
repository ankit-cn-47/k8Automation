#!/bin/bash

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Install Ansible
echo "Installing Ansible..."
sudo apt-get install -y ansible

# Generate SSH key pair if not exist
SSH_KEY="$HOME/.ssh/id_rsa"
if [ ! -f "$SSH_KEY" ]; then
  echo "Generating SSH key pair..."
  ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
else
  echo "SSH key pair already exists."
fi

# Prompt for target hosts
echo "Please enter the target hosts (comma-separated):"
read -r TARGET_HOSTS

# Add target hosts to Ansible inventory
INVENTORY_FILE="/etc/ansible/hosts"
echo "Updating Ansible inventory at $INVENTORY_FILE..."
sudo bash -c "echo '[targets]' > $INVENTORY_FILE"
IFS=',' read -r -a HOST_ARRAY <<< "$TARGET_HOSTS"
for HOST in "${HOST_ARRAY[@]}"; do
  echo "Adding $HOST to Ansible inventory..."
  sudo bash -c "echo $HOST >> $INVENTORY_FILE"
done

echo "Ansible master node configuration is complete."
echo "Remember to copy the SSH public key to the target hosts using:"
echo "ssh-copy-id user@host"


# chmod +x initAnsible.sh
