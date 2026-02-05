# Hyprland - Wayland compositor
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Hyprland from flake for freshness
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
  };

  # Portal setup - Hyprland flake handles portal-hyprland automatically
  xdg.portal.enable = true;

  # Session-critical packages only (recovery, plumbing)
  # User tools (waybar, mako, wofi) are in home/hyprland.nix via programs.*
  environment.systemPackages = with pkgs; [
    # Wayland plumbing
    wl-clipboard
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
  ];

  # Polkit for authentication dialogs
  security.polkit.enable = true;

  # Secrets - let niri.nix handle this to avoid duplication
  # services.gnome.gnome-keyring.enable is set by programs.niri
}
