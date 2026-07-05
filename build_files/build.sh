#!/bin/bash

set -ouex pipefail

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
  erikreider/SwayNotificationCenter # for swaync
  errornointernet/packages
  leloubil/wl-clip-persist
  tofik/sway
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
  swaylock
  brightnessctl
  fuzzel
  mako
  waybar
  xwayland-satellite
  gnome-keyring
  wireplumber
  xdg-desktop-portal-gnome
  xdg-desktop-portal-gtk
)

ADDITIONAL_SYSTEM_APPS=(
  kitty
  kitty-terminfo
  alternateved/keyd
)

# we do all package installs in one rpm-ostree command
# so that we create minimal layers in the final image
log "Installing packages using dnf5..."
dnf5 install --setopt=install_weak_deps=False -y \
  "${NIRI_PKGS[@]}" \
  "${ADDITIONAL_SYSTEM_APPS[@]}"

#######################################################################
### Disable repositeories so they aren't cluttering up the final image

log "Disable Copr repos to get rid of clutter..."
for repo in "${COPR_REPOS[@]}"; do
  dnf5 -y copr disable "$repo"
done
#### Example for enabling a System Unit File

systemctl preset brew-setup.service brew-update.timer brew-upgrade.timer
