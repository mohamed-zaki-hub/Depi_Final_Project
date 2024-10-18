#!/bin/bash

# Path to the private key
PRIVATE_KEY_PATH="~/desktop/keys/labsuser.pem"

# Apply Terraform configuration
terraform apply -auto-approve

# Extract the public IPs
jenkins_master_ip=$(terraform output -raw jenkins_master_public_ip)
jenkins_agent_ip=$(terraform output -raw jenkins_agent_public_ip)

# Create an Ansible hosts file with the extracted IPs from terraform
cat <<EOF > hosts
[ec2]
jenkins_master ansible_host=$jenkins_master_ip ansible_ssh_private_key_file=$PRIVATE_KEY_PATH ansible_user=ubuntu
jenkins_agent ansible_host=$jenkins_agent_ip ansible_ssh_private_key_file=$PRIVATE_KEY_PATH ansible_user=ubuntu
EOF

# Check SSH connection to ensure instances are running so that playbook will run correctly 
# So keep trying every 5 seconds untill ssh connection is made successfully with maximum time of 3 minutes
TIMEOUT=180
START_TIME=$(date +%s)

while ! ssh -i $PRIVATE_KEY_PATH -o ConnectTimeout=3 -o StrictHostKeyChecking=no ubuntu@$jenkins_master_ip "exit" 2>/dev/null; do
  CURRENT_TIME=$(date +%s)
  ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
  echo $jenkins_master_ip
  
  if [ $ELAPSED_TIME -ge $TIMEOUT ]; then
    echo "Timeout reached. Could't connect to instances"
    exit 1
  fi
  
  echo "........Waiting for instance to be ready...."
  sleep 5
done

echo "Instances are ready. Ansible playbook is running now."

# Run the Ansible playbook
ansible-playbook config-jenkins-playbook.yml
