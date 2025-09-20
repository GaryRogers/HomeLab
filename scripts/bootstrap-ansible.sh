#!/bin/bash

#===============================================================================
# Ansible Bootstrap Script
#===============================================================================
# Description: Sets up Ansible on Ubuntu with proper user management,
#              directory structure, and initial configuration
# Author: HomeLab
# Version: 1.0
# Usage: sudo ./bootstrap-ansible.sh
#===============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
ANSIBLE_HOME="/opt/ansible"
ANSIBLE_USER="ansible"
ANSIBLE_GROUP="ansible"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

# Check if running as root or with sudo
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Install Ansible if not already installed
install_ansible() {
    log_step "Installing Ansible"
    
    if command -v ansible >/dev/null 2>&1; then
        local version=$(ansible --version | head -n1)
        log_warning "Ansible is already installed: $version"
        return 0
    fi
    
    log_info "Updating package lists..."
    apt update -qq
    
    log_info "Installing Ansible..."
    apt install -y ansible
    
    local version=$(ansible --version | head -n1)
    log_success "Ansible installed successfully: $version"
}

# Create ansible user and group
create_ansible_user() {
    log_step "Setting up Ansible user and group"
    
    # Create group if it doesn't exist
    if ! getent group "$ANSIBLE_GROUP" >/dev/null 2>&1; then
        log_info "Creating ansible group..."
        groupadd --system "$ANSIBLE_GROUP"
        log_success "Created group: $ANSIBLE_GROUP"
    else
        log_warning "Group '$ANSIBLE_GROUP' already exists"
    fi
    
    # Create user if it doesn't exist
    if ! id "$ANSIBLE_USER" >/dev/null 2>&1; then
        log_info "Creating ansible user..."
        useradd --system --gid "$ANSIBLE_GROUP" --shell /bin/bash --create-home --home-dir "$ANSIBLE_HOME" "$ANSIBLE_USER"
        log_success "Created user: $ANSIBLE_USER"
    else
        log_warning "User '$ANSIBLE_USER' already exists"
    fi
    
    # Add current user to ansible group (if not root)
    if [[ -n "${SUDO_USER:-}" ]] && [[ "$SUDO_USER" != "root" ]]; then
        if ! groups "$SUDO_USER" | grep -q "$ANSIBLE_GROUP"; then
            log_info "Adding user '$SUDO_USER' to ansible group..."
            usermod -aG "$ANSIBLE_GROUP" "$SUDO_USER"
            log_success "Added '$SUDO_USER' to group '$ANSIBLE_GROUP'"
        else
            log_warning "User '$SUDO_USER' is already in group '$ANSIBLE_GROUP'"
        fi
    fi
}

# Create directory structure
create_directory_structure() {
    log_step "Creating Ansible directory structure"
    
    local directories=(
        "$ANSIBLE_HOME"
        "$ANSIBLE_HOME/inventory"
        "$ANSIBLE_HOME/inventory/group_vars"
        "$ANSIBLE_HOME/inventory/host_vars"
        "$ANSIBLE_HOME/playbooks"
        "$ANSIBLE_HOME/roles"
        "$ANSIBLE_HOME/files"
        "$ANSIBLE_HOME/templates"
        "$ANSIBLE_HOME/tmp"
        "$ANSIBLE_HOME/logs"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_info "Creating directory: $dir"
            mkdir -p "$dir"
        else
            log_warning "Directory already exists: $dir"
        fi
    done
    
    # Create symlink for templates in playbooks directory
    log_info "Creating symlink for templates in playbooks directory"
    local playbooks_templates_link="$ANSIBLE_HOME/playbooks/templates"
    if [[ -L "$playbooks_templates_link" ]]; then
        log_warning "Templates symlink already exists in playbooks directory"
    elif [[ -e "$playbooks_templates_link" ]]; then
        log_warning "Templates path already exists as a file/directory in playbooks"
    else
        ln -s ../templates "$playbooks_templates_link"
        log_success "Created templates symlink in playbooks directory"
    fi
    
    log_success "Directory structure created"
}

# Create initial inventory file
create_inventory() {
    log_step "Creating initial inventory configuration"
    
    local inventory_file="$ANSIBLE_HOME/inventory/inventory.yaml"
    
    if [[ -f "$inventory_file" ]]; then
        log_warning "Inventory file already exists: $inventory_file"
        log_info "Backing up existing inventory to ${inventory_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$inventory_file" "${inventory_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    log_info "Creating inventory file: $inventory_file"
    tee "$inventory_file" > /dev/null <<EOF
# Ansible Inventory Configuration
# Generated by bootstrap-ansible.sh on $(date)

all:
  children:
    # Production servers
    servers:
      hosts:
        homelab:
          ansible_host: 192.168.4.100
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
    
    # Local machine for testing
    local:
      hosts:
        localhost:
          ansible_connection: local
          ansible_python_interpreter: "{{ ansible_playbook_python }}"

  vars:
    # Global variables
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    ansible_become: true
    ansible_become_method: sudo
EOF
    
    log_success "Inventory file created: $inventory_file"
}

# Create basic ansible configuration
create_ansible_config() {
    log_step "Creating Ansible configuration file"
    
    local config_file="$ANSIBLE_HOME/ansible.cfg"
    
    if [[ -f "$config_file" ]]; then
        log_warning "Configuration file already exists: $config_file"
        return 0
    fi
    
    log_info "Creating configuration file: $config_file"
    tee "$config_file" > /dev/null <<EOF
# Ansible Configuration
# Generated by bootstrap-ansible.sh on $(date)

[defaults]
inventory = $ANSIBLE_HOME/inventory/inventory.yaml
remote_user = ubuntu
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
bin_ansible_callbacks = True
log_path = $ANSIBLE_HOME/logs/ansible.log
roles_path = $ANSIBLE_HOME/roles
library = $ANSIBLE_HOME/library
module_utils = $ANSIBLE_HOME/module_utils
action_plugins = $ANSIBLE_HOME/action_plugins
lookup_plugins = $ANSIBLE_HOME/lookup_plugins
filter_plugins = $ANSIBLE_HOME/filter_plugins

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
pipelining = True
EOF
    
    log_success "Configuration file created: $config_file"
}

# Set proper permissions
set_permissions() {
    log_step "Setting permissions"
    
    log_info "Setting ownership to $ANSIBLE_USER:$ANSIBLE_GROUP"
    chown -R "$ANSIBLE_USER:$ANSIBLE_GROUP" "$ANSIBLE_HOME"
    
    log_info "Setting directory permissions"
    find "$ANSIBLE_HOME" -type d -exec chmod 770 {} \;
    
    log_info "Setting file permissions"
    find "$ANSIBLE_HOME" -type f -exec chmod 640 {} \;
    
    log_success "Permissions set successfully"
}

# Main execution
main() {
    echo -e "${GREEN}"
    echo "==============================================================================="
    echo "                          Ansible Bootstrap Script"
    echo "==============================================================================="
    echo -e "${NC}"
    echo "This script will set up Ansible with:"
    echo "  • Install Ansible package"
    echo "  • Create ansible user and group"
    echo "  • Set up directory structure in $ANSIBLE_HOME"
    echo "  • Create initial inventory and configuration"
    echo "  • Set proper permissions"
    echo ""
    
    check_privileges
    install_ansible
    create_ansible_user
    create_directory_structure
    create_inventory
    create_ansible_config
    set_permissions
    
    echo ""
    echo -e "${GREEN}==============================================================================="
    echo "                             Setup Complete!"
    echo "===============================================================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Log out and back in for group membership to take effect"
    echo "  2. Edit the inventory file: $ANSIBLE_HOME/inventory/inventory.yaml"
    echo "  3. Configure SSH keys for remote hosts"
    echo "  4. Test connectivity: ansible all -m ping"
    echo ""
    echo "Useful commands:"
    echo "  • View inventory: ansible-inventory --list"
    echo "  • Test connection: ansible all -m ping"
    echo "  • Run ad-hoc command: ansible all -a 'uptime'"
    echo ""
    log_success "Ansible bootstrap completed successfully!"
}

# Run main function
main "$@"