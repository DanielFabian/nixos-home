# Display manager / greeter - tuigreet (terminal-based, zero deps)
# Picks up all installed wayland sessions automatically
{ config, pkgs, ... }:

{
  # greetd + tuigreet - lightweight, no compositor conflict
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

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
