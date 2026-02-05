# Niri - Scrollable-tiling Wayland compositor
# Spartan setup for portal debugging
{ config, pkgs, ... }:

{
  # Enable Niri compositor (nixpkgs module handles base portals)
  programs.niri = {
    enable = true;
    useNautilus = false; # Use GTK portal for file dialogs
  };

  # FIX: portal-gnome doesn't implement OpenURI, only portal-kde does
  xdg.portal = {
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.niri = {
      # KDE portal for OpenURI (the only one that implements it!)
      "org.freedesktop.impl.portal.OpenURI" = "kde";
      # GTK for file dialogs (already set by programs.niri, but be explicit)
      "org.freedesktop.impl.portal.FileChooser" = "gtk";
      # Fallback
      default = [
        "kde"
        "gtk"
      ];
    };
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
