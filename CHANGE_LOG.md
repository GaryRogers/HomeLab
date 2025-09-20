# CHANGE_LOG

## 2025-09-20

- Added [Ansible Bootstrap script](scripts/bootstrap-ansible.sh) to get Ansible installed and the directory structure in place.
- Added [Bonjour service](ansible/playbooks/bonjour.yaml) to make our name resolution easier on the network. No CoreDNS and setting the DNS Servers on the router.
- Added [local.yaml](ansible/playbooks/local.yaml) for base ansible installs/config
- Added [wake-gamingpc.sh](scripts/wake-gamingpc.sh) to send wake-on-lan to gaming PC
- Added [firewall.yaml](ansible/playbooks/firewall.yaml) to set up the local firewall
- Added 8080 (k3s API) to the firewall
- Added a [k3s.yaml](ansible/playbooks/k3s.yaml) playbook just to handle the permissions on the config file for k3s