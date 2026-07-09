#!/bin/bash

set -ouex pipefail

log() {
  echo "=== $* ==="
}

### Install staged filesystem content

# Merge local system_files and the upstream brew payload into the image root.
cp -a /ctx/system_files/. /
rm -f /.gitkeep

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

#######################################################################
# Setup Repositories
#######################################################################

log "Enable Copr repos..."
COPR_REPOS=(
  alternateved/keyd
  lionheartp/Hyprland
  ulysg/xwayland-satellite
  yalter/niri
)
for repo in "${COPR_REPOS[@]}"; do
  # Try to enable the repo, but don't fail the build if it doesn't support this Fedora version
  if ! dnf5 -y copr enable "$repo" 2>&1; then
    log "Warning: Failed to enable COPR repo $repo (may not support Fedora $RELEASE)"
  fi
done

#######################################################################
## Install Packages
#######################################################################

# Niri and its dependencies from its default config.
# commented out packages are already referenced in this file, OR they
# are prebundled inside our parent image.
NIRI_PKGS=(
  niri
  brightnessctl
  mako
  xwayland-satellite
  noctalia-git
)

ADDITIONAL_SYSTEM_APPS=(
  kitty
  kitty-terminfo
  keyd
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# we do all package installs in one rpm-ostree command
# so that we create minimal layers in the final image
log "Installing packages using dnf5..."
dnf5 install --setopt=install_weak_deps=False -y \
  "${NIRI_PKGS[@]}" \
  "${ADDITIONAL_SYSTEM_APPS[@]}"

#######################################################################
## Remove Packages
#######################################################################

EXCLUDED_PACKAGES=(
  cosign
  fedora-bookmarks
  fedora-chromium-config
  fedora-chromium-config-gnome
  firefox
  firefox-langpacks
  gnome-extensions-app
  gnome-shell-extension-background-logo
  gnome-software
  gnome-software-rpm-ostree
  gnome-terminal-nautilus
  yelp
)

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
  readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
  if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
    dnf -y remove "${INSTALLED_EXCLUDED[@]}"
  else
    echo "No excluded packages found to remove."
  fi
fi

#######################################################################
### Disable repositeories so they aren't cluttering up the final image

log "Disable Copr repos to get rid of clutter..."
for repo in "${COPR_REPOS[@]}"; do
  dnf5 -y copr disable "$repo"
done
#### Example for enabling a System Unit File

systemctl preset brew-setup.service brew-update.timer brew-upgrade.timer
