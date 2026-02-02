# Hyprland - Wayland compositor
{ config, pkgs, inputs, ... }:

{
  # Hyprland from flake for freshness
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  # XDG portal for screen sharing, file dialogs, etc
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Recommended utilities (home-manager handles most config)
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    wl-clipboard
    wlr-randr
    
    # Screenshots
    grim
    slurp
    
    # Screen recording
    wf-recorder
    
    # Notification daemon
    mako
    
    # App launcher - wofi (wayland-native rofi alternative)
    wofi
    
    # Status bar (home-manager configures waybar)
    waybar
    
    # Qt Wayland support
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
  ];

  # Polkit for authentication dialogs
  security.polkit.enable = true;
  
  # Gnome keyring for secrets
  services.gnome.gnome-keyring.enable = true;

  # Enable greetd display manager (lightweight, Wayland-native)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };
}
