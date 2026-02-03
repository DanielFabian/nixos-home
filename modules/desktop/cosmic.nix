# COSMIC Desktop Environment (System76)
{ config, pkgs, ... }:

{
  # Enable COSMIC DE
  services.desktopManager.cosmic.enable = true;

  # COSMIC uses its own greeter - but we keep greetd with tuigreet
  # so user can choose between Hyprland, COSMIC, Plasma at login

  # Note: COSMIC is still in alpha, expect rough edges
  # It will appear as a session option in greetd
}
