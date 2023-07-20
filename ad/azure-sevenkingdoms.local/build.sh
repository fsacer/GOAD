#!/bin/bash

# Generate a random password
echo "Generating password..."
password=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 30)

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform
terraform init

# Plan Terraform
echo "Planning Terraform..."
terraform plan -out tfplan -var "password=$password"

# Apply Terraform
echo "Applying Terraform..."
terraform apply tfplan

# Get the public IP address of the VM
echo "Getting jumpbox IP address..."
public_ip=$(terraform output -raw ubuntu-jumpbox-ip)

# Run setup script on the jumpbox
echo "Running setup script on jumpbox..."
cd ..
ssh -o "StrictHostKeyChecking no" -i ssh_keys/ubuntu-jumpbox.pem goad@$public_ip 'bash -s' <scripts/setup.sh

# Replace the password in the Ansible inventory file
echo "Replacing password in Ansible inventory file..."
ssh -i ssh_keys/ubuntu-jumpbox.pem goad@$public_ip "sed -i 's/YourSuperSecretPassword/$password/g' GOAD/ad/azure-sevenkingdoms.local/inventory"

# Run the Ansible playbook
echo "Running Ansible playbook..."
ssh -i ssh_keys/ubuntu-jumpbox.pem goad@$public_ip 'bash -s' <scripts/provisionning.sh

echo "Ubuntu jumpbox IP: $public_ip"
echo "goadmin password: $password"

echo "You can now connect to the jumpbox using the following command:"
echo "ssh -i ssh_keys/ubuntu-jumpbox.pem goad@$public_ip"
