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

  # Login manager - greetd is minimal, launches niri-session directly
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "dany"; # TODO: make configurable
      };
    };
  };

  # Config goes in ~/.config/niri/config.kdl

  # Add niri utilities and dependencies
  environment.systemPackages = with pkgs; [
    # Terminal (essential - can't recover without one)
    foot

    # Niri-specific tools
    nirius # utility commands for niri

    # Screen locker (niri default)
    swaylock

    # App launcher
    fuzzel

    # Clipboard
    wl-clipboard

    # Keyring UI (if needed)
    seahorse
  ];

  # Swaylock needs PAM
  security.pam.services.swaylock = { };
}
