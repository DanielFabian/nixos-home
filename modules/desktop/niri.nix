# Niri - Scrollable-tiling Wayland compositor
{ config, pkgs, ... }:

{
  # Enable Niri compositor
  # nixpkgs module sets up: portal-gnome (screencast), portal-gtk (files), gnome-keyring
  # OpenURI is built into xdg-desktop-portal itself (no backend needed)
  programs.niri = {
    enable = true;
    useNautilus = false; # Use GTK portal for file dialogs (lighter than Nautilus)
  };

  # Config goes in ~/.config/niri/config.kdl

  # Session-critical packages only
  # Terminal, launcher, bar etc. are in home/ via programs.*
  environment.systemPackages = with pkgs; [
    nirius # niri utility commands
  ];
}
