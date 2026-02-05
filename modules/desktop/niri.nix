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

  # Login manager - greetd with tuigreet for session picking
  # (TPM auto-unlocks disk, so we need *some* auth before desktop)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
        user = "greeter";
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
