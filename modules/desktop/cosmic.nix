# COSMIC Desktop Environment (System76)
{ config, pkgs, ... }:

{
  # Enable COSMIC DE
  services.desktopManager.cosmic.enable = true;

  # Note: COSMIC is still in alpha, expect rough edges
  # It will appear as a session option in GDM
}
