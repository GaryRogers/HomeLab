#!/bin/bash

#===============================================================================
# Wake Gaming PC Script
#===============================================================================
# Description: Sends a Wake-on-LAN packet to wake up the gaming PC for
#              Ollama requests and other services
# Author: HomeLab
# Version: 1.0
# Usage: ./wake-gamingpc.sh
#===============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration - Update these values for your gaming PC
GAMING_PC_MAC="00:00:00:00:00:00"  # Replace with your gaming PC's MAC address
GAMING_PC_IP="192.168.4.101"       # Replace with your gaming PC's IP address
GAMING_PC_NAME="GamingPC"
BROADCAST_IP="192.168.4.255"       # Replace with your network's broadcast address
WOL_PORT="9"                       # Standard WOL port (usually 7 or 9)

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

# Check if wakeonlan tool is available
check_wakeonlan() {
    if ! command -v wakeonlan >/dev/null 2>&1; then
        log_error "wakeonlan command not found!"
        log_info "Please install it using one of the following methods:"
        echo "  • macOS: brew install wakeonlan"
        echo "  • Ubuntu/Debian: sudo apt install wakeonlan"
        echo "  • CentOS/RHEL: sudo yum install net-tools"
        exit 1
    fi
}

# Validate MAC address format
validate_mac_address() {
    local mac_regex="^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
    if [[ ! "$GAMING_PC_MAC" =~ $mac_regex ]]; then
        log_error "Invalid MAC address format: $GAMING_PC_MAC"
        log_info "Please update GAMING_PC_MAC in this script with a valid MAC address"
        log_info "Format should be: XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX"
        exit 1
    fi
}

# Check if gaming PC is already awake
check_if_awake() {
    log_step "Checking if $GAMING_PC_NAME is already awake"
    
    if ping -c 1 -W 2000 "$GAMING_PC_IP" >/dev/null 2>&1; then
        log_success "$GAMING_PC_NAME ($GAMING_PC_IP) is already awake and responding"
        return 0
    else
        log_info "$GAMING_PC_NAME ($GAMING_PC_IP) is not responding to ping"
        return 1
    fi
}

# Send Wake-on-LAN packet
send_wol_packet() {
    log_step "Sending Wake-on-LAN packet to $GAMING_PC_NAME"
    
    log_info "Target MAC: $GAMING_PC_MAC"
    log_info "Target IP: $GAMING_PC_IP"
    log_info "Broadcast IP: $BROADCAST_IP"
    
    if wakeonlan -i "$BROADCAST_IP" -p "$WOL_PORT" "$GAMING_PC_MAC"; then
        log_success "Wake-on-LAN packet sent successfully"
    else
        log_error "Failed to send Wake-on-LAN packet"
        return 1
    fi
}

# Wait for gaming PC to wake up
wait_for_wakeup() {
    log_step "Waiting for $GAMING_PC_NAME to wake up"
    
    local max_attempts=30  # Wait up to 5 minutes (30 * 10 seconds)
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt $attempt/$max_attempts: Checking if $GAMING_PC_NAME is awake..."
        
        if ping -c 1 -W 2000 "$GAMING_PC_IP" >/dev/null 2>&1; then
            log_success "$GAMING_PC_NAME is now awake and responding!"
            log_info "You can now connect to Ollama or other services"
            return 0
        fi
        
        sleep 10
        ((attempt++))
    done
    
    log_warning "$GAMING_PC_NAME did not respond within the timeout period"
    log_info "This could mean:"
    echo "  • Wake-on-LAN is not properly configured on the target machine"
    echo "  • The machine is taking longer than expected to boot"
    echo "  • Network connectivity issues"
    echo "  • Incorrect MAC or IP address"
    return 1
}

# Display configuration info
show_config() {
    echo -e "${GREEN}"
    echo "==============================================================================="
    echo "                          Wake Gaming PC Script"
    echo "==============================================================================="
    echo -e "${NC}"
    echo "Configuration:"
    echo "  • Gaming PC Name: $GAMING_PC_NAME"
    echo "  • MAC Address: $GAMING_PC_MAC"
    echo "  • IP Address: $GAMING_PC_IP"
    echo "  • Broadcast IP: $BROADCAST_IP"
    echo "  • WOL Port: $WOL_PORT"
    echo ""
}

# Main execution
main() {
    show_config
    
    # Validate configuration
    if [[ "$GAMING_PC_MAC" == "00:00:00:00:00:00" ]]; then
        log_error "Please update the GAMING_PC_MAC variable with your gaming PC's actual MAC address"
        exit 1
    fi
    
    check_wakeonlan
    validate_mac_address
    
    # Check if already awake
    if check_if_awake; then
        echo ""
        log_info "No action needed - $GAMING_PC_NAME is already running"
        exit 0
    fi
    
    # Send WOL packet and wait
    send_wol_packet
    wait_for_wakeup
    
    echo ""
    echo -e "${GREEN}==============================================================================="
    echo "                                 Complete!"
    echo "===============================================================================${NC}"
    echo ""
    echo "Your gaming PC should now be awake and ready for:"
    echo "  • Ollama API requests"
    echo "  • SSH connections"
    echo "  • Remote desktop"
    echo "  • Other network services"
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --config       Show current configuration"
        echo "  --check        Only check if gaming PC is awake (no WOL)"
        echo ""
        echo "Configuration:"
        echo "  Edit the variables at the top of this script to match your setup"
        exit 0
        ;;
    --config)
        show_config
        exit 0
        ;;
    --check)
        show_config
        check_if_awake
        exit $?
        ;;
    "")
        # Default behavior - run main function
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac