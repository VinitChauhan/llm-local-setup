#!/bin/bash

# Mac Intel Memory & CPU Cleanup Script
# Comprehensive cleanup for Intel-based Mac systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}[HEADER]${NC} $1"
}

print_action() {
    echo -e "${PURPLE}[ACTION]${NC} $1"
}

# Function to get system info
get_system_info() {
    print_header "System Information"
    echo "macOS Version: $(sw_vers -productVersion)"
    echo "Hardware: $(sysctl -n machdep.cpu.brand_string)"
    echo "Memory: $(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}')"
    echo "CPU Cores: $(sysctl -n hw.ncpu)"
    echo ""
}

# Function to show current memory usage
show_memory_usage() {
    print_header "Current Memory Usage"
    vm_stat | grep -E "(Pages free|Pages active|Pages inactive|Pages speculative|Pages wired down)" | awk '
    BEGIN { 
        page_size = 4096 
    }
    /Pages free/ { 
        free = $3 * page_size / 1024 / 1024 / 1024
        printf "Free Memory: %.2f GB\n", free
    }
    /Pages active/ { 
        active = $3 * page_size / 1024 / 1024 / 1024
        printf "Active Memory: %.2f GB\n", active
    }
    /Pages inactive/ { 
        inactive = $3 * page_size / 1024 / 1024 / 1024
        printf "Inactive Memory: %.2f GB\n", inactive
    }
    /Pages wired/ { 
        wired = $4 * page_size / 1024 / 1024 / 1024
        printf "Wired Memory: %.2f GB\n", wired
    }'
    echo ""
}

# Function to show top memory consuming processes
show_top_memory_processes() {
    print_header "Top 10 Memory Consuming Processes"
    ps aux | sort -k4 -nr | head -11 | awk 'NR==1{print $0} NR>1{printf "%-8s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $11}'
    echo ""
}

# Function to show top CPU consuming processes
show_top_cpu_processes() {
    print_header "Top 10 CPU Consuming Processes"
    ps aux | sort -k3 -nr | head -11 | awk 'NR==1{print $0} NR>1{printf "%-8s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $11}'
    echo ""
}

# Function to clear memory caches
clear_memory_caches() {
    print_action "Clearing memory caches..."
    
    # Clear DNS cache
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    print_success "DNS cache cleared"
    
    # Clear system caches
    sudo rm -rf /System/Library/Caches/* 2>/dev/null || true
    sudo rm -rf /Library/Caches/* 2>/dev/null || true
    print_success "System caches cleared"
    
    # Clear user caches
    rm -rf ~/Library/Caches/* 2>/dev/null || true
    print_success "User caches cleared"
    
    # Clear font caches
    sudo atsutil databases -remove 2>/dev/null || true
    print_success "Font caches cleared"
    
    # Purge inactive memory (if available)
    if command -v purge >/dev/null 2>&1; then
        sudo purge
        print_success "Inactive memory purged"
    fi
}

# Function to clean temporary files
clean_temp_files() {
    print_action "Cleaning temporary files..."
    
    # Clean /tmp directory
    sudo rm -rf /tmp/* 2>/dev/null || true
    print_success "System temp files cleaned"
    
    # Clean user temp files
    rm -rf /var/folders/*/*/*/T/* 2>/dev/null || true
    print_success "User temp files cleaned"
    
    # Clean Downloads folder (optional - ask user)
    # read -p "Clean Downloads folder? (y/n): " -n 1 -r
    # echo
    # if [[ $REPLY =~ ^[Yy]$ ]]; then
    #     rm -rf ~/Downloads/* 2>/dev/null || true
    #     print_success "Downloads folder cleaned"
    # fi
    
    # Clean Trash
    rm -rf ~/.Trash/* 2>/dev/null || true
    print_success "Trash emptied"
}

# Function to clean logs
clean_logs() {
    print_action "Cleaning log files..."
    
    # System logs
    sudo rm -rf /var/log/* 2>/dev/null || true
    print_success "System logs cleaned"
    
    # User logs
    rm -rf ~/Library/Logs/* 2>/dev/null || true
    print_success "User logs cleaned"
    
    # Console logs
    rm -rf ~/Library/Containers/*/Data/Library/Logs/* 2>/dev/null || true
    print_success "Console logs cleaned"
}

# Function to optimize storage
optimize_storage() {
    print_action "Optimizing storage..."
    
    # Clean Xcode derived data (if exists)
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
        print_success "Xcode derived data cleaned"
    fi
    
    # Clean iOS device support files
    if [ -d ~/Library/Developer/Xcode/iOS\ DeviceSupport ]; then
        find ~/Library/Developer/Xcode/iOS\ DeviceSupport -name "*.dSYM" -exec rm -rf {} + 2>/dev/null || true
        print_success "iOS device support files cleaned"
    fi
    
    # Clean Docker if installed
    if command -v docker >/dev/null 2>&1; then
        docker system prune -f --volumes 2>/dev/null || true
        print_success "Docker cleanup completed"
    fi
    
    # Clean npm cache if node is installed
    if command -v npm >/dev/null 2>&1; then
        npm cache clean --force 2>/dev/null || true
        print_success "npm cache cleaned"
    fi
    
    # Clean pip cache if python is installed
    if command -v pip3 >/dev/null 2>&1; then
        pip3 cache purge 2>/dev/null || true
        print_success "pip cache cleaned"
    fi
}

# Function to kill high resource processes
kill_resource_heavy_processes() {
    print_action "Identifying resource-heavy processes..."
    
    # Show processes using more than 10% CPU
    print_header "Processes using >10% CPU:"
    ps aux | awk '$3 > 10.0 {printf "%-8s %-6s %-6s%% %-6s%% %s\n", $1, $2, $3, $4, $11}'
    
    # Show processes using more than 5% memory
    print_header "Processes using >5% Memory:"
    ps aux | awk '$4 > 5.0 {printf "%-8s %-6s %-6s%% %-6s%% %s\n", $1, $2, $3, $4, $11}'
    
    echo ""
    read -p "Do you want to kill any specific processes? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter process name or PID (or 'skip' to continue): " process_input
        if [[ $process_input != "skip" ]]; then
            if [[ $process_input =~ ^[0-9]+$ ]]; then
                # It's a PID
                kill -TERM "$process_input" 2>/dev/null && print_success "Process $process_input terminated"
            else
                # It's a process name
                pkill -f "$process_input" 2>/dev/null && print_success "Process '$process_input' terminated"
            fi
        fi
    fi
}

# Function to restart essential services
restart_services() {
    print_action "Restarting essential services..."
    
    # Restart Finder
    killall Finder 2>/dev/null || true
    print_success "Finder restarted"
    
    # Restart Dock
    killall Dock 2>/dev/null || true
    print_success "Dock restarted"
    
    # Restart WindowServer (requires admin - optional)
    read -p "Restart WindowServer? (will log out all users) (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo killall -HUP WindowServer 2>/dev/null || true
        print_success "WindowServer restarted"
    fi
}

# Function to optimize system settings
# optimize_system_settings() {
#     print_action "Optimizing system settings..."
    
#     # Disable visual effects for better performance
#     defaults write com.apple.dock expose-animation-duration -float 0.1
#     defaults write com.apple.dock launchanim -bool false
#     defaults write com.apple.dock mineffect -string "scale"
#     defaults write com.apple.universalaccess reduceMotion -bool true
#     defaults write com.apple.universalaccess reduceTransparency -bool true
    
#     print_success "Visual effects optimized for performance"
    
#     # Set energy saver settings for performance
#     sudo pmset -a hibernatemode 0
#     sudo pmset -a standby 0
#     sudo pmset -a autopoweroff 0
    
#     print_success "Energy settings optimized"
# }

# Function to show disk usage
show_disk_usage() {
    print_header "Disk Usage Information"
    df -h | grep -E "(Filesystem|/dev/disk)"
    echo ""
    
    print_header "Largest directories in home folder:"
    du -h ~/* 2>/dev/null | sort -hr | head -10
    echo ""
}

# Function to check for malware/suspicious processes
check_suspicious_processes() {
    print_action "Checking for suspicious processes..."
    
    # Check for high CPU processes that might be malware
    suspicious_processes=$(ps aux | grep -v grep | awk '$3 > 50.0 {print $2, $11}' | head -5)
    
    if [ -n "$suspicious_processes" ]; then
        print_warning "Found processes with very high CPU usage:"
        echo "$suspicious_processes"
    else
        print_success "No obviously suspicious processes found"
    fi
}

# Main execution
main() {
    print_header "Mac Intel System Cleanup & Optimization Tool"
    print_status "Starting system analysis and cleanup..."
    echo ""
    
    # Check if running as admin for some operations
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. Some user-specific cleanups may not work properly."
    fi
    
    # System information
    get_system_info
    
    # Show current resource usage
    show_memory_usage
    show_top_memory_processes
    show_top_cpu_processes
    show_disk_usage
    
    # Check for suspicious processes
    check_suspicious_processes
    
    echo ""
    read -p "Proceed with cleanup? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Cleanup cancelled by user"
        exit 0
    fi
    
    # Perform cleanup operations
    clear_memory_caches
    clean_temp_files
    clean_logs
    optimize_storage
    kill_resource_heavy_processes
    
    # Optional optimizations
    echo ""
    read -p "Apply system optimizations? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # optimize_system_settings
        restart_services
    fi
    
    echo ""
    print_success "Cleanup completed!"
    
    # Show results
    print_header "Post-cleanup system status:"
    show_memory_usage
    show_disk_usage
    
    print_header "Recommendations:"
    echo "1. Restart your Mac for full effect"
    echo "2. Run this script weekly for maintenance"
    echo "3. Monitor Activity Monitor for persistent issues"
    echo "4. Consider upgrading RAM if memory usage remains high"
    echo "5. Use 'top' or 'htop' commands to monitor real-time usage"
}

# Run main function
main "$@"