#!/bin/bash
cd "$(dirname "$0")"
vagrant up
ansible-playbook -i inventory.ini install_k3s.yaml