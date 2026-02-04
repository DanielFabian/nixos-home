# Niri - Scrollable-tiling Wayland compositor
{ config, pkgs, ... }:

{
  # Enable Niri compositor
  programs.niri = {
    enable = true;
    useNautilus = true; # Use GNOME portal infrastructure (OpenURI, file dialogs)
  };

  # Niri will appear as a session option in GDM
  # Config goes in ~/.config/niri/config.kdl (home-manager manages it)

  # Secrets service (VS Code, etc need this)
  services.gnome.gnome-keyring.enable = true;

  # Add niri utilities and dependencies
  environment.systemPackages = with pkgs; [
    # Niri-specific tools
    nirius # utility commands for niri

    # Screen locker (niri default)
    swaylock

    # Keyring UI (if needed)
    seahorse

    # We reuse from hyprland: foot, wofi, waybar, mako
  ];

  # Swaylock needs PAM
  security.pam.services.swaylock = { };
}
