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

  # Waybar for niri (DMS is an alternative but let's have waybar as fallback)
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "cpu"
          "memory"
          "network"
          "battery"
          "tray"
        ];

        clock = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "{:%A, %B %d, %Y}";
        };
        cpu.format = "CPU {usage}%";
        memory.format = "MEM {}%";
        battery = {
          format = "BAT {capacity}%";
          format-charging = "CHG {capacity}%";
        };
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
      }
      window#waybar {
        background: rgba(26, 27, 38, 0.9);
        color: #c0caf5;
      }
      #workspaces button {
        color: #c0caf5;
        padding: 0 5px;
      }
      #workspaces button.active {
        color: #7aa2f7;
      }
    '';
  };

  # Niri-specific tools
  home.packages = with pkgs; [
    fuzzel # app launcher

    # Screenshots
    grim
    slurp

    # Screen recording
    wf-recorder

    # Notifications
    mako

    # Network tray
    networkmanagerapplet
  ];
}
