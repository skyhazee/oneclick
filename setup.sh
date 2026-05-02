#!/usr/bin/env bash
# ============================================================================
#  ___  _  _ ___ ___ _    ___ ___ _  __
# / _ \| \| | __/ __| |  |_ _/ __| |/ /
#| (_) | .` | _| (__| |__ | | (__| ' <
# \___/|_|\_|___\___|____|___\___|_|\_\
#
# Ubuntu One-Click Setup Script
# Author : skyhaze
# Repo   : https://github.com/skyhazee/oneclick
# License: MIT
# ============================================================================
# This script performs:
#   1. Debloating - Remove unnecessary packages for performance
#   2. App Installation - Telegram, Termius, Chrome, Discord
#   3. Discord Auto-Start on login
#   4. System Optimization - Kernel tweaks, GNOME perf, GRUB, firewall
#   5. Essential Dev Tools
#   6. Firewall Setup
#   7. WiFi Power Saving Disable
#   8. Final Cleanup
# ============================================================================

set -euo pipefail

# ── Non-interactive mode ─────────────────────────────────────────────────────
# Prevent all interactive prompts from apt/dpkg during install/upgrade
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
apt_options=(-y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")

# ── Colors & Formatting ─────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Logging Helpers ──────────────────────────────────────────────────────────
log_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}${BOLD}  $1${NC}"
    echo -e "${MAGENTA}${BOLD}══════════════════════════════════════════════════════════════${NC}"
}

log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[✔]${NC}      $1"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC}      $1"; }
log_error()   { echo -e "${RED}[✘]${NC}      $1"; }
log_step()    { echo -e "${CYAN}[→]${NC}      $1"; }

# ── Snap Install with Retry ──────────────────────────────────────────────────
# Usage: snap_install_retry <snap_name> [max_retries]
# Retries snap install up to N times (default 3) with delay between attempts.
# Returns 0 on success, 1 on failure (does NOT exit the script).
snap_install_retry() {
    local snap_name="$1"
    local max_retries="${2:-3}"
    local attempt=1

    while [[ $attempt -le $max_retries ]]; do
        log_info "Snap install attempt ${attempt}/${max_retries} for ${snap_name}..."
        log_info "Snap may download large dependencies (this can take several minutes, please wait)..."
        if snap install "$snap_name" 2>&1; then
            return 0
        fi

        if [[ $attempt -lt $max_retries ]]; then
            log_warning "Snap install failed for ${snap_name}, retrying in 10 seconds..."
            sleep 10
        fi
        ((attempt++))
    done

    log_error "Failed to install ${snap_name} after ${max_retries} attempts (network issue?). Skipping."
    return 1
}

# ── Pre-flight Checks ───────────────────────────────────────────────────────
preflight() {
    log_header "PRE-FLIGHT CHECKS"

    # Must be Ubuntu
    if ! grep -qi 'ubuntu' /etc/os-release 2>/dev/null; then
        log_error "This script is designed for Ubuntu. Exiting."
        exit 1
    fi

    # Must run as root / sudo
    if [[ $EUID -ne 0 ]]; then
        log_error "Please run with sudo:  sudo bash setup.sh"
        exit 1
    fi

    # Detect the real user (not root)
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_HOME=$(eval echo "~${REAL_USER}")

    log_success "OS detected: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
    log_success "Running as: root (real user: ${REAL_USER})"
    log_success "Home directory: ${REAL_HOME}"

    echo ""
    echo -e "${YELLOW}${BOLD}This script will:${NC}"
    echo -e "  ${CYAN}1.${NC} Remove bloatware & unnecessary packages"
    echo -e "  ${CYAN}2.${NC} Install Telegram, Termius, Chrome, Discord"
    echo -e "  ${CYAN}3.${NC} Set Discord to auto-start on login"
    echo -e "  ${CYAN}4.${NC} Optimize system performance (kernel, GNOME, GRUB)"
    echo -e "  ${CYAN}5.${NC} Install essential dev tools"
    echo -e "  ${CYAN}6.${NC} Configure firewall (UFW)"
    echo -e "  ${CYAN}7.${NC} Disable WiFi power saving"
    echo -e "  ${CYAN}8.${NC} Clean up & free disk space"
    echo ""

    read -rp "$(echo -e "${BOLD}Continue? [y/N]: ${NC}")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warning "Aborted by user."
        exit 0
    fi
}

# ── 1. Debloat ───────────────────────────────────────────────────────────────
debloat() {
    log_header "STEP 1/8 — DEBLOATING UBUNTU"

    # Packages to remove (safe to remove, won't break desktop)
    local bloat_packages=(
        # Games
        aisleriot
        gnome-mahjongg
        gnome-mines
        gnome-sudoku
        gnome-2048

        # Media (rarely used defaults)
        rhythmbox
        shotwell
        totem
        cheese

        # Office / Productivity (most people use alternatives)
        libreoffice-*
        simple-scan

        # Communication
        thunderbird

        # Other bloat
        gnome-maps
        gnome-weather
        gnome-contacts
        gnome-calendar
        gnome-clocks
        gnome-characters
        gnome-font-viewer
        gnome-logs
        gnome-power-manager
        orca
        brltty
        duplicity
        deja-dup
        remmina
        transmission-*
        usb-creator-*
        gnome-todo
        gnome-text-editor

        # Snap store (optional — we keep snapd but remove the GUI store)
        snap-store

        # Ubuntu report / telemetry
        ubuntu-report
        popularity-contest
        apport
        whoopsie
    )

    log_step "Removing bloatware packages..."
    for pkg in "${bloat_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*${pkg}" 2>/dev/null; then
            apt-get remove --purge "${apt_options[@]}" "$pkg" 2>/dev/null && \
                log_success "Removed: ${pkg}" || \
                log_warning "Could not remove: ${pkg}"
        fi
    done

    # Disable unnecessary services
    log_step "Disabling unnecessary services..."
    local services_to_disable=(
        apport.service
        whoopsie.service
        motd-news.timer
        gpu-manager.service
    )

    for svc in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            systemctl disable --now "$svc" 2>/dev/null && \
                log_success "Disabled service: ${svc}" || \
                log_warning "Could not disable: ${svc}"
        fi
    done

    # Disable Ubuntu error reporting
    if [[ -f /etc/default/apport ]]; then
        sed -i 's/enabled=1/enabled=0/' /etc/default/apport
        log_success "Disabled apport error reporting"
    fi

    log_success "Debloating complete!"
}

# ── 2. Install Applications ─────────────────────────────────────────────────
install_apps() {
    log_header "STEP 2/8 — INSTALLING APPLICATIONS"

    # Update repos first
    log_step "Updating package lists..."
    apt-get update -qq

    # ── Google Chrome ────────────────────────────────────────────────────
    log_step "Installing Google Chrome..."
    if ! command -v google-chrome &>/dev/null; then
        wget -q -O /tmp/chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
        apt-get install "${apt_options[@]}" /tmp/chrome.deb
        rm -f /tmp/chrome.deb
        log_success "Google Chrome installed"
    else
        log_info "Google Chrome already installed, skipping"
    fi

    # ── Telegram ─────────────────────────────────────────────────────────
    log_step "Installing Telegram Desktop..."
    if ! snap list telegram-desktop &>/dev/null; then
        snap_install_retry telegram-desktop || true
        if snap list telegram-desktop &>/dev/null; then
            log_success "Telegram Desktop installed (snap)"
        fi
    else
        log_info "Telegram already installed, skipping"
    fi

    # ── Discord ──────────────────────────────────────────────────────────
    log_step "Installing Discord..."
    if ! command -v discord &>/dev/null; then
        wget -q -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
        apt-get install "${apt_options[@]}" /tmp/discord.deb
        rm -f /tmp/discord.deb
        log_success "Discord installed"
    else
        log_info "Discord already installed, skipping"
    fi

    # ── Termius ──────────────────────────────────────────────────────────
    log_step "Installing Termius..."
    if ! snap list termius-app &>/dev/null; then
        snap_install_retry termius-app || true
        if snap list termius-app &>/dev/null; then
            log_success "Termius installed (snap)"
        fi
    else
        log_info "Termius already installed, skipping"
    fi

    log_success "All applications installed!"
}

# ── 3. Discord Auto-Start ────────────────────────────────────────────────────
setup_discord_autostart() {
    log_header "STEP 3/8 — DISCORD AUTO-START"

    local autostart_dir="${REAL_HOME}/.config/autostart"
    mkdir -p "$autostart_dir"

    cat > "${autostart_dir}/discord.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Discord
Comment=All-in-one voice and text chat
Exec=/usr/bin/discord --start-minimized
Icon=discord
Terminal=false
Categories=Network;InstantMessaging;
X-GNOME-Autostart-enabled=true
StartupWMClass=discord
EOF

    chown "${REAL_USER}:${REAL_USER}" "${autostart_dir}/discord.desktop"
    chmod 644 "${autostart_dir}/discord.desktop"

    log_success "Discord will auto-start on login (minimized)"
}

# ── 4. System Optimization ──────────────────────────────────────────────────
optimize_system() {
    log_header "STEP 4/8 — SYSTEM OPTIMIZATION"

    # ── Kernel / sysctl tweaks ───────────────────────────────────────────
    log_step "Applying kernel performance tweaks..."

    cat > /etc/sysctl.d/99-performance.conf <<EOF
# ── Oneclick Performance Tuning ──

# Reduce swap usage (use RAM more aggressively)
vm.swappiness=10

# Better cache management
vm.vfs_cache_pressure=50

# Increase inotify watchers (for dev tools, IDEs, file watchers)
fs.inotify.max_user_watches=524288

# Network performance
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
EOF

    sysctl --system &>/dev/null
    log_success "Kernel tweaks applied"

    # ── GNOME Performance Tweaks (if GNOME is installed) ─────────────────
    if command -v gsettings &>/dev/null; then
        log_step "Applying GNOME performance tweaks..."

        # Run gsettings as the real user
        sudo -u "$REAL_USER" bash -c '
            # Reduce animations
            gsettings set org.gnome.desktop.interface enable-animations true

            # Faster animation speed (if available)
            gsettings set org.gnome.desktop.interface gtk-enable-animations true 2>/dev/null

            # Disable file indexing (saves CPU & disk)
            gsettings set org.freedesktop.Tracker3.Miner.Files crawling-interval -2 2>/dev/null
            gsettings set org.freedesktop.Tracker3.Miner.Files enable-monitors false 2>/dev/null

            # Minimize background activity
            gsettings set org.gnome.desktop.search-providers disable-external true 2>/dev/null

            # Show battery percentage (useful for laptops)
            gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null

            # Better font rendering
            gsettings set org.gnome.desktop.interface font-antialiasing "rgba" 2>/dev/null
            gsettings set org.gnome.desktop.interface font-hinting "slight" 2>/dev/null
        '
        log_success "GNOME tweaks applied"
    fi

    # ── GRUB Optimization ────────────────────────────────────────────────
    log_step "Optimizing GRUB boot config..."

    if [[ -f /etc/default/grub ]]; then
        # Backup original
        cp /etc/default/grub /etc/default/grub.bak.oneclick

        # Reduce boot timeout to 2 seconds
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub

        # Quiet boot (less verbose, faster perceived boot)
        if ! grep -q "quiet splash" /etc/default/grub; then
            sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
        fi

        update-grub &>/dev/null
        log_success "GRUB optimized (timeout: 2s, quiet boot)"
    fi

    # ── Preload (frequently used apps load faster) ───────────────────────
    log_step "Installing preload for faster app launches..."
    if ! command -v preload &>/dev/null; then
        apt-get install "${apt_options[@]}" preload &>/dev/null
        systemctl enable preload &>/dev/null
        log_success "Preload installed & enabled"
    else
        log_info "Preload already installed"
    fi

    log_success "System optimization complete!"
}

# ── 5. Install Dev Tools ────────────────────────────────────────────────────
install_dev_tools() {
    log_header "STEP 5/8 — ESSENTIAL DEV TOOLS"

    local dev_packages=(
        git
        curl
        wget
        htop
        neofetch
        build-essential
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release
        unzip
        zip
        net-tools
        jq
        tree
        vim
        xclip
    )

    log_step "Installing essential tools..."
    apt-get install "${apt_options[@]}" "${dev_packages[@]}" &>/dev/null

    for pkg in "${dev_packages[@]}"; do
        if dpkg -l "$pkg" &>/dev/null; then
            log_success "Installed: ${pkg}"
        fi
    done

    # ── Configure Git (basic) ────────────────────────────────────────────
    log_step "Setting up Git defaults..."
    sudo -u "$REAL_USER" bash -c '
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        git config --global core.editor vim
    '
    log_success "Git configured (default branch: main)"

    log_success "Dev tools installed!"
}

# ── 6. Firewall Setup ───────────────────────────────────────────────────────
setup_firewall() {
    log_header "STEP 6/8 — FIREWALL (UFW)"

    log_step "Configuring UFW firewall..."

    if ! command -v ufw &>/dev/null; then
        apt-get install "${apt_options[@]}" ufw &>/dev/null
    fi

    ufw default deny incoming &>/dev/null
    ufw default allow outgoing &>/dev/null

    # Allow SSH (in case you need remote access)
    ufw allow ssh &>/dev/null

    # Enable firewall
    echo "y" | ufw enable &>/dev/null

    log_success "Firewall enabled (deny incoming, allow outgoing, SSH allowed)"
}

# ── 7. Disable WiFi Power Saving ─────────────────────────────────────────────
disable_wifi_powersave() {
    log_header "STEP 7/8 — DISABLE WIFI POWER SAVING"

    # Auto-detect wireless interface
    local wifi_iface
    wifi_iface=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -1)

    if [[ -z "$wifi_iface" ]]; then
        # Fallback: try /sys/class/net
        for iface in /sys/class/net/*; do
            if [[ -d "${iface}/wireless" ]]; then
                wifi_iface=$(basename "$iface")
                break
            fi
        done
    fi

    if [[ -z "$wifi_iface" ]]; then
        log_warning "No wireless interface detected, skipping WiFi power saving config"
        return 0
    fi

    log_info "Detected wireless interface: ${wifi_iface}"

    # Disable power saving immediately
    log_step "Disabling WiFi power saving on ${wifi_iface}..."
    if command -v iwconfig &>/dev/null; then
        iwconfig "$wifi_iface" power off 2>/dev/null && \
            log_success "WiFi power saving disabled (immediate)" || \
            log_warning "Could not disable power saving immediately (iwconfig)"
    elif command -v iw &>/dev/null; then
        iw dev "$wifi_iface" set power_save off 2>/dev/null && \
            log_success "WiFi power saving disabled (immediate)" || \
            log_warning "Could not disable power saving immediately (iw)"
    fi

    # Make it permanent via NetworkManager dispatcher script
    log_step "Making WiFi power saving disable permanent..."
    local nm_dispatcher_dir="/etc/NetworkManager/dispatcher.d"
    if [[ -d "$(dirname "$nm_dispatcher_dir")" ]]; then
        mkdir -p "$nm_dispatcher_dir"
        cat > "${nm_dispatcher_dir}/99-wifi-powersave-off" <<'DISPATCHER_EOF'
#!/usr/bin/env bash
# Disable WiFi power saving on interface up
# Installed by OneClick setup script

INTERFACE="$1"
ACTION="$2"

if [[ "$ACTION" == "up" ]]; then
    # Check if this is a wireless interface
    if [[ -d "/sys/class/net/${INTERFACE}/wireless" ]]; then
        /usr/sbin/iwconfig "$INTERFACE" power off 2>/dev/null || \
        /usr/sbin/iw dev "$INTERFACE" set power_save off 2>/dev/null
    fi
fi
DISPATCHER_EOF
        chmod 755 "${nm_dispatcher_dir}/99-wifi-powersave-off"
        log_success "NetworkManager dispatcher script installed"
    fi

    # Also set via NetworkManager config (belt and suspenders)
    local nm_conf_dir="/etc/NetworkManager/conf.d"
    mkdir -p "$nm_conf_dir"
    cat > "${nm_conf_dir}/99-wifi-powersave-off.conf" <<'NM_CONF_EOF'
[connection]
wifi.powersave = 2
NM_CONF_EOF
    log_success "NetworkManager config set (wifi.powersave = 2 = disabled)"

    # Restart NetworkManager to apply
    if systemctl is-active NetworkManager &>/dev/null; then
        systemctl restart NetworkManager 2>/dev/null
        log_success "NetworkManager restarted to apply changes"
    fi

    log_success "WiFi power saving permanently disabled for all wireless interfaces!"
}

# ── 8. Cleanup ───────────────────────────────────────────────────────────────
cleanup() {
    log_header "STEP 8/8 — CLEANUP & DISK SPACE"

    log_step "Removing unused packages..."
    apt-get autoremove --purge "${apt_options[@]}" &>/dev/null
    log_success "Autoremove complete"

    log_step "Cleaning apt cache..."
    apt-get autoclean "${apt_options[@]}" &>/dev/null
    apt-get clean &>/dev/null
    log_success "Apt cache cleaned"

    log_step "Clearing old journal logs (keep 3 days)..."
    journalctl --vacuum-time=3d &>/dev/null
    log_success "Journal logs trimmed"

    # Show disk space saved
    log_info "Current disk usage:"
    df -h / | tail -1 | awk '{print "  Used: "$3" / "$2" ("$5" used) — Free: "$4}'
}

# ── Summary ──────────────────────────────────────────────────────────────────
show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  ✅ SETUP COMPLETE!${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}What was done:${NC}"
    echo -e "  ${GREEN}✔${NC} Bloatware removed"
    echo -e "  ${GREEN}✔${NC} Google Chrome installed"
    echo -e "  ${GREEN}✔${NC} Telegram Desktop installed"
    echo -e "  ${GREEN}✔${NC} Discord installed (auto-start enabled)"
    echo -e "  ${GREEN}✔${NC} Termius installed"
    echo -e "  ${GREEN}✔${NC} System optimized (kernel, GNOME, GRUB)"
    echo -e "  ${GREEN}✔${NC} Dev tools installed"
    echo -e "  ${GREEN}✔${NC} Firewall configured"
    echo -e "  ${GREEN}✔${NC} WiFi power saving disabled"
    echo -e "  ${GREEN}✔${NC} Disk cleaned up"
    echo ""
    echo -e "  ${YELLOW}${BOLD}⚡ Recommended: Reboot your system now!${NC}"
    echo -e "  ${CYAN}   Run: ${BOLD}sudo reboot${NC}"
    echo ""
    echo -e "  ${MAGENTA}Made with ❤ by skyhaze${NC}"
    echo -e "  ${MAGENTA}https://github.com/skyhazee/oneclick${NC}"
    echo ""

    read -rp "$(echo -e "${BOLD}Reboot now? [y/N]: ${NC}")" reboot_confirm
    if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
        log_info "Rebooting in 5 seconds..."
        sleep 5
        reboot
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "  ___  _  _ ___ ___ _    ___ ___ _  __"
    echo " / _ \\| \\| | __/ __| |  |_ _/ __| |/ /"
    echo "| (_) | .\` | _| (__| |__ | | (__| ' < "
    echo " \\___/|_|\\_|___\\___|____|___\\___|_|\\_\\"
    echo ""
    echo -e "  Ubuntu One-Click Setup Script v1.1${NC}"
    echo ""

    preflight

    debloat
    install_apps
    setup_discord_autostart
    optimize_system
    install_dev_tools
    setup_firewall
    disable_wifi_powersave
    cleanup
    show_summary
}

main "$@"
