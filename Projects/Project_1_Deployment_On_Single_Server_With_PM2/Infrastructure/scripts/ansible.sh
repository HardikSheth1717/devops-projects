#!/bin/bash
set -e

sudo apt-add-repository -y ppa:ansible/ansible

# Update package repositories
sudo apt update

# Install Ansible
sudo apt install -y ansible
