# Flatpak - Rolling apps layer (FHS sandbox)
{ config, pkgs, ... }:

{
  # Enable flatpak daemon
  services.flatpak.enable = true;

  # XDG portal improvements for FHS apps
  xdg.portal.xdgOpenUsePortal = true;

  # System-wide flatpak management
  environment.systemPackages = with pkgs; [
    flatpak
    gnome-software # GUI for browsing/installing flatpaks
  ];

  # Note: Flathub must be added manually after first boot:
  #   sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  #
  # Then install rolling apps:
  #   flatpak install flathub org.mozilla.firefox
  #   flatpak install flathub com.google.Chrome
  #   flatpak install flathub com.spotify.Client
  #
  # Philosophy: Nix manages the daemon, you manage the apps.
  # These are mutable by design - the "rolling" in rolling apps.
}
