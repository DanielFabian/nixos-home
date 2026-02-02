# KDE Plasma - fallback desktop environment
{ config, pkgs, ... }:

{
  # Plasma 6 (Wayland-native)
  services.desktopManager.plasma6.enable = true;

  # SDDM can offer both Plasma and Hyprland sessions
  # But we're using greetd - Plasma session will be available there too

  # Plasma pulls in a lot, but useful as fallback
  # Can select "Plasma (Wayland)" or "Plasma (X11)" from greetd

  # KDE apps that are useful even outside Plasma
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin       # file manager
    kdePackages.konsole       # terminal (backup)
    kdePackages.ark           # archive manager
    kdePackages.spectacle     # screenshots
    kdePackages.gwenview      # image viewer
  ];
}
