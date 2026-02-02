# Hyprland user configuration
{ config, pkgs, inputs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    systemd.enable = true;  # integrate with systemd user session
    
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "foot";
      "$menu" = "wofi --show drun";
      
      # Monitor config - auto for now, customize per-setup later
      monitor = [ ",preferred,auto,1" ];
      
      # General appearance
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(7aa2f7ff)";    # Tokyo Night blue
        "col.inactive_border" = "rgba(414868ff)";
        layout = "dwindle";
      };
      
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 5;
          passes = 2;
        };
        drop_shadow = true;
        shadow_range = 15;
        shadow_render_power = 3;
      };
      
      animations = {
        enabled = true;
        bezier = "ease,0.25,0.1,0.25,1";
        animation = [
          "windows,1,4,ease"
          "windowsOut,1,4,ease,popin 80%"
          "fade,1,4,ease"
          "workspaces,1,4,ease"
        ];
      };
      
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      
      # Keybindings - vim-style (adapted for Colemak-DH)
      # NOTE: Colemak-DH moves hjkl → neio or mnei depending on philosophy
      # Using physical position (qwerty hjkl = colemak mnei)
      bind = [
        # Core actions
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $menu"
        "$mod, Q, killactive"
        "$mod SHIFT, E, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"
        "$mod, P, pseudo"          # dwindle
        "$mod, S, togglesplit"     # dwindle
        
        # Focus movement (vim hjkl positions on Colemak-DH → m n e i)
        "$mod, m, movefocus, l"
        "$mod, n, movefocus, d"
        "$mod, e, movefocus, u"
        "$mod, i, movefocus, r"
        
        # Window movement
        "$mod SHIFT, m, movewindow, l"
        "$mod SHIFT, n, movewindow, d"
        "$mod SHIFT, e, movewindow, u"
        "$mod SHIFT, i, movewindow, r"
        
        # Resize
        "$mod CTRL, m, resizeactive, -50 0"
        "$mod CTRL, n, resizeactive, 0 50"
        "$mod CTRL, e, resizeactive, 0 -50"
        "$mod CTRL, i, resizeactive, 50 0"
        
        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        
        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        
        # Scratchpad
        "$mod, grave, togglespecialworkspace"
        "$mod SHIFT, grave, movetoworkspace, special"
        
        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print, exec, grim - | wl-copy"
      ];
      
      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      
      # Startup
      exec-once = [
        "waybar"
        "mako"
        # Set wallpaper - TODO: integrate with wallpaper rotation
        # "swaybg -i ~/wallpapers/current.png -m fill"
      ];
    };
  };

  # Waybar config
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "cpu" "memory" "network" "battery" "tray" ];
        
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
}
