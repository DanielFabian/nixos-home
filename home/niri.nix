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

  # Niri-specific tools (DMS provides panel/launcher, but fuzzel is a lightweight fallback)
  home.packages = with pkgs; [
    fuzzel # app launcher

    # Screenshots
    grim
    slurp

    # Screen recording
    wf-recorder
  ];
}
