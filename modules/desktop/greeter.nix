# Display manager / greeter - COSMIC greeter
# GPU-accelerated login screen with session picker, wallpaper, dark theme
{ config, pkgs, ... }:

{
  # COSMIC greeter (runs cosmic-comp for the login screen, uses greetd under the hood)
  services.displayManager.cosmic-greeter.enable = true;

  # Shared session infrastructure
  programs.dconf.enable = true; # GTK theming (dark mode preference)
  security.pam.services.swaylock = { }; # Screen locker PAM

  # Shared packages across all Wayland sessions
  environment.systemPackages = with pkgs; [
    swaylock # Screen locker
    wl-clipboard # Clipboard (used by niri + hyprland)
    seahorse # Keyring UI
  ];
}
