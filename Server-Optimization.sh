#!/bin/bash

# Linux Server Optimization and Security Implementation Script
# With Colored Output and Logging
# For Red Hat Enterprise Linux (RHEL)

# -------------------------------
# 🎨 Color Codes
# -------------------------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# -------------------------------
# 📢 Color Functions
# -------------------------------
info() {
    echo -e "${BLUE}[INFO] $1${RESET}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${RESET}"
}

error() {
    echo -e "${RED}[ERROR] $1${RESET}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${RESET}"
}

# -------------------------------
# 📄 Setup Variables
# -------------------------------
LOGFILE="/var/log/server_setup.log"

# -------------------------------
# ⚡ Ensure script is run as root
# -------------------------------
if [[ $EUID -ne 0 ]]; then
    error "Run this script as root."
    exit 1
fi

# -------------------------------
# 📦 Install Required Packages
# -------------------------------
required_packages=("dhcp-server" "vsftpd" "httpd" "net-tools" "setroubleshoot-server" "policycoreutils-python-utils")

info "Installing required packages..."
for pkg in "${required_packages[@]}"; do
    if ! rpm -q "$pkg" >/dev/null; then
        yum install -y "$pkg" >> "$LOGFILE" 2>&1
        success "Installed $pkg."
    else
        info "$pkg is already installed."
    fi
done

# -------------------------------
# 🌐 Configure DHCP Server
# -------------------------------
configure_dhcp() {
    info "Configuring DHCP server..."
    cat > /etc/dhcp/dhcpd.conf <<EOF
default-lease-time 600;
max-lease-time 7200;
subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.100 192.168.1.200;
  option routers 192.168.1.1;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

    systemctl enable dhcpd >> "$LOGFILE" 2>&1
    systemctl start dhcpd >> "$LOGFILE" 2>&1
    success "DHCP server configured and started."
}

# -------------------------------
# 📂 Configure FTP Server
# -------------------------------
configure_ftp() {
    info "Configuring FTP server..."
    systemctl enable vsftpd >> "$LOGFILE" 2>&1
    systemctl start vsftpd >> "$LOGFILE" 2>&1
    success "FTP server configured and started."
}

# -------------------------------
# 🌍 Configure Apache Server
# -------------------------------
configure_apache() {
    info "Configuring Apache (HTTP) server..."
    systemctl enable httpd >> "$LOGFILE" 2>&1
    systemctl start httpd >> "$LOGFILE" 2>&1
    success "Apache server configured and started."
}

# -------------------------------
# 🔥 Configure Firewall Rules
# -------------------------------
configure_firewall() {
    info "Configuring firewall rules..."
    firewall-cmd --permanent --add-service=http >> "$LOGFILE" 2>&1
    firewall-cmd --permanent --add-service=ftp >> "$LOGFILE" 2>&1
    firewall-cmd --permanent --add-service=dhcp >> "$LOGFILE" 2>&1
    firewall-cmd --reload >> "$LOGFILE" 2>&1
    success "Firewall rules applied successfully."
}

# -------------------------------
# 🔒 Configure SELinux
# -------------------------------
configure_selinux() {
    info "Configuring SELinux settings..."

    setsebool -P ftp_home_dir=1 >> "$LOGFILE" 2>&1
    setsebool -P httpd_can_network_connect=1 >> "$LOGFILE" 2>&1

    success "SELinux policies adjusted for FTP and HTTP services."
}

# -------------------------------
# 🛠️ System Performance Optimization
# -------------------------------
optimize_system() {
    info "Applying system performance optimizations..."

    # Example: Increase file descriptor limits
    echo "* soft nofile 65535" >> /etc/security/limits.conf
    echo "* hard nofile 65535" >> /etc/security/limits.conf

    # Example: Tuning sysctl
    cat >> /etc/sysctl.conf <<EOF
net.core.somaxconn = 1024
net.ipv4.tcp_syncookies = 1
vm.swappiness = 10
EOF
    sysctl -p >> "$LOGFILE" 2>&1

    success "Performance tuning applied."
}

# -------------------------------
# 📈 Monitor Server Health
# -------------------------------
monitor_server() {
    info "Monitoring current server performance..."

    echo ""
    echo -e "${YELLOW}Top 5 Processes by Memory Usage:${RESET}"
    ps aux --sort=-%mem | head -n 6

    echo ""
    echo -e "${YELLOW}Disk Usage:${RESET}"
    df -h

    echo ""
    echo -e "${YELLOW}Network Statistics:${RESET}"
    ss -tuln
}

# -------------------------------
# 📜 Main Menu
# -------------------------------
while true; do
    echo ""
    echo "--------------------------------------------"
    echo -e "${YELLOW}  Linux Server Optimization & Security  ${RESET}"
    echo "--------------------------------------------"
    echo "1. Configure DHCP Server"
    echo "2. Configure FTP Server"
    echo "3. Configure Apache Server"
    echo "4. Configure Firewall Rules"
    echo "5. Configure SELinux Policies"
    echo "6. Apply System Optimization"
    echo "7. Monitor Server Performance"
    echo "8. Exit"
    echo "--------------------------------------------"
    read -p "Enter your choice [1-8]: " choice

    case "$choice" in
        1) configure_dhcp ;;
        2) configure_ftp ;;
        3) configure_apache ;;
        4) configure_firewall ;;
        5) configure_selinux ;;
        6) optimize_system ;;
        7) monitor_server ;;
        8) info "Exiting script. Goodbye!"
           exit 0 ;;
        *) warning "Invalid option! Please try again." ;;
    esac
done
