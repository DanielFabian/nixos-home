# Niri - Scrollable-tiling Wayland compositor
{ config, pkgs, ... }:

{
  # Enable Niri compositor
  programs.niri = {
    enable = true;
    useNautilus = false; # We use KDE portals (Dolphin for file dialogs)
  };

  # Niri will appear as a session option in SDDM
  # Config goes in ~/.config/niri/config.kdl (DMS manages it via includes)

  # Add niri utilities and dependencies
  environment.systemPackages = with pkgs; [
    # Niri-specific tools
    nirius # utility commands for niri

    # Screen locker (niri default)
    swaylock

    # Keyring UI (if needed)
    seahorse

    # DMS provides: waybar-like panel, notifications, launcher
    # We still keep foot terminal from hyprland config
  ];

  # Swaylock needs PAM
  security.pam.services.swaylock = { };
}
