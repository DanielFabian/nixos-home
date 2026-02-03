# Niri - Scrollable-tiling Wayland compositor
{ config, pkgs, ... }:

{
  # Enable Niri compositor
  programs.niri = {
    enable = true;
    useNautilus = false; # we're not using GNOME stack
  };

  # Niri will appear as a session option in greetd
  # Config goes in ~/.config/niri/config.kdl (managed manually or via home-manager)

  # Add some useful utilities for niri
  environment.systemPackages = with pkgs; [
    # Niri-specific tools
    nirius # utility commands for niri

    # Already have these from hyprland, but good to list
    waybar
    wofi
    mako
  ];
}
