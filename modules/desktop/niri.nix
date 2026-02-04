# Niri - Scrollable-tiling Wayland compositor
# Spartan setup for portal debugging
{ config, pkgs, ... }:

{
  # Enable Niri compositor (nixpkgs module handles portals)
  programs.niri = {
    enable = true;
    useNautilus = false; # Use GTK portal for file dialogs
  };

  # Minimal login manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "dany";
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
