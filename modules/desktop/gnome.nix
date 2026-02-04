# GNOME - fallback desktop environment + infrastructure for niri
# GNOME provides the portal backends, keyring, settings that modern apps expect
{ config, pkgs, ... }:

{
  # GNOME desktop manager
  services.desktopManager.gnome.enable = true;

  # GNOME pulls in:
  # - xdg-desktop-portal-gnome (OpenURI, FileChooser, etc.)
  # - gnome-keyring (secrets)
  # - gsettings/dconf (app settings)
  # - nautilus (file dialogs)
  # This makes Flatpak apps "just work"

  # Can select "GNOME" or "GNOME Classic" from greetd

  # Exclude some GNOME apps we don't need (niri has its own stack)
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany # browser - we use firefox
    geary # email - not needed
    gnome-music
    gnome-photos
    totem # video - we use mpv
  ];

  # Keep useful GNOME apps available everywhere
  environment.systemPackages = with pkgs; [
    nautilus # file manager (needed for portal file dialogs)
    gnome-calculator
    gnome-system-monitor
    file-roller # archive manager
    loupe # image viewer
    gnome-text-editor # simple text editor
  ];
}
