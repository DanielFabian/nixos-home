# KDE Plasma - full desktop stack with portals, SDDM, etc.
# Provides the infrastructure that modern apps expect
{ config, pkgs, ... }:

{
  # Plasma 6 (Wayland-native)
  services.desktopManager.plasma6.enable = true;

  # SDDM display manager (KDE's native DM)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Plasma provides:
  # - xdg-desktop-portal-kde (OpenURI, FileChooser, etc.)
  # - kwallet (secrets)
  # - System settings
  # This makes Flatpak apps "just work"

  # KDE apps useful everywhere
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin # file manager
    kdePackages.konsole # terminal (backup)
    kdePackages.ark # archive manager
    kdePackages.spectacle # screenshots
    kdePackages.gwenview # image viewer
    kdePackages.kate # text editor
  ];

  # Keyring - kwallet is enabled automatically with Plasma
  # but we also enable gnome-keyring for apps that expect it
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
}
