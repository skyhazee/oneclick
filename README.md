<p align="center">
  <img src="https://img.shields.io/badge/OS-Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" />
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" />
</p>

<h1 align="center">⚡ OneClick — Ubuntu Setup Script</h1>

<p align="center">
  <strong>Debloat, optimize, and set up your fresh Ubuntu install in one command.</strong><br>
  No more wasting hours configuring after every reinstall.
</p>

---

## 🚀 Quick Start

### One-Line Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/skyhazee/oneclick/main/setup.sh)"
```

> ⚠️ **Requires `sudo`** — The script will ask for confirmation before making changes.

### Alternative: Clone & Run

```bash
git clone https://github.com/skyhazee/oneclick.git
cd oneclick
sudo bash setup.sh
```

---

## 📋 What Does It Do?

| Step | Action | Details |
|------|--------|---------|
| **1** | 🗑️ **Debloat** | Removes bloatware (games, LibreOffice, Thunderbird, etc.) |
| **2** | 📦 **Install Apps** | Google Chrome, Telegram, Discord, Termius |
| **3** | 🔄 **Auto-Start** | Discord launches minimized on login |
| **4** | ⚡ **Optimize** | Kernel tweaks, GNOME perf, GRUB speedup, preload |
| **5** | 🛠️ **Dev Tools** | git, curl, htop, build-essential, vim, jq, etc. |
| **6** | 🔒 **Firewall** | UFW configured (deny in, allow out, SSH open) |
| **7** | 🧹 **Cleanup** | Autoremove, cache clean, journal trim |

---

## 🗑️ Debloated Packages

The following are **safely removed** without breaking your desktop:

<details>
<summary>Click to see full list</summary>

**Games:**
- Aisleriot (Solitaire), Mahjongg, Mines, Sudoku, 2048

**Media:**
- Rhythmbox, Shotwell, Totem (Videos), Cheese (Webcam)

**Office:**
- LibreOffice (all modules), Simple Scan

**Communication:**
- Thunderbird

**GNOME Extras:**
- Maps, Weather, Contacts, Calendar, Clocks, Characters, Font Viewer, Logs, To Do, Text Editor

**System:**
- Ubuntu Report, Popularity Contest, Apport (crash reporter), Whoopsie
- Brltty, Orca (accessibility — reinstall if needed)
- Déjà Dup, Duplicity, Remmina, Transmission, USB Creator

</details>

---

## 📦 Installed Applications

| App | Install Method | Description |
|-----|---------------|-------------|
| **Google Chrome** | `.deb` | Web browser |
| **Telegram Desktop** | Snap | Messaging |
| **Discord** | `.deb` | Voice & text chat (auto-start enabled) |
| **Termius** | Snap | SSH client |

---

## ⚡ System Optimizations

### Kernel Tweaks (`/etc/sysctl.d/99-performance.conf`)

```ini
vm.swappiness=10                         # Use RAM more, swap less
vm.vfs_cache_pressure=50                 # Better file cache management
fs.inotify.max_user_watches=524288       # For IDEs & file watchers
net.core.rmem_max=16777216               # Network buffer optimization
net.ipv4.tcp_fastopen=3                  # Faster TCP connections
```

### GNOME Tweaks
- Tracker (file indexing) disabled → saves CPU & disk
- External search providers disabled
- Better font rendering (rgba antialiasing)

### GRUB
- Boot timeout reduced to **2 seconds**
- Quiet boot enabled

### Preload
- Learns your most-used apps and preloads them into memory for faster launch

---

## 🛠️ Dev Tools Installed

```
git, curl, wget, htop, neofetch, build-essential,
software-properties-common, apt-transport-https,
ca-certificates, gnupg, lsb-release, unzip, zip,
net-tools, jq, tree, vim, xclip
```

---

## 🔒 Firewall Rules

```
Default incoming:  DENY
Default outgoing:  ALLOW
SSH (port 22):     ALLOW
```

---

## 📁 Project Structure

```
oneclick/
├── setup.sh        # Main setup script
├── README.md       # This file
└── LICENSE          # MIT License
```

---

## ⚙️ Requirements

- **OS:** Ubuntu 20.04 / 22.04 / 24.04+ (Desktop)
- **Arch:** x86_64 (amd64)
- **Privileges:** `sudo` / root access
- **Internet:** Required for downloading packages

---

## 🔧 Customization

Want to modify what gets installed or removed? Edit `setup.sh`:

- **Add/remove bloat packages:** Edit the `bloat_packages` array in the `debloat()` function
- **Add/remove apps:** Modify the `install_apps()` function
- **Change kernel tweaks:** Edit the `optimize_system()` function
- **Change autostart apps:** Modify `setup_discord_autostart()` function

---

## ❓ FAQ

**Q: Is it safe to run?**
> Yes. The script asks for confirmation before starting and only removes packages that are safe to remove. A GRUB backup is created before modification.

**Q: Can I run it multiple times?**
> Yes. The script checks if packages are already installed/removed and skips them.

**Q: What if I need LibreOffice later?**
> Simply reinstall it: `sudo apt install libreoffice`

**Q: Does it work on Ubuntu Server?**
> It's designed for Ubuntu Desktop. Server doesn't have the GNOME/GUI packages to remove, but it won't break anything.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/skyhazee">skyhaze</a>
</p>
