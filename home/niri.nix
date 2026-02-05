# Niri user configuration
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Niri config - symlink to repo file for live editing
  # Edit ~/nixos-home/home/niri-config.kdl directly, then reload niri
  xdg.configFile."niri/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/nixos-home/home/niri-config.kdl";

  # DMS provides: panel, notifications, launcher, network widget
  # So we only need screenshot/recording tools here
  home.packages = with pkgs; [
    fuzzel # app launcher (fallback / keyboard-driven)

    # Screenshots
    grim
    slurp

    # Screen recording
    wf-recorder
  ];
}
