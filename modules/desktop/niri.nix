# Niri - Scrollable-tiling Wayland compositor
{ config, pkgs, ... }:

{
  # Enable Niri compositor
  programs.niri = {
    enable = true;
    useNautilus = false; # we're not using GNOME stack
  };

  # Niri will appear as a session option in greetd
  # Config goes in ~/.config/niri/config.kdl (home-manager manages it)

  # Add niri utilities and dependencies
  environment.systemPackages = with pkgs; [
    # Niri-specific tools
    nirius # utility commands for niri

    # Screen locker (niri default)
    swaylock

    # We reuse from hyprland: foot, wofi, waybar, mako
  ];

  # Swaylock needs PAM
  security.pam.services.swaylock = { };
}
