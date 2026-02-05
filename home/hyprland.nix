# Hyprland user configuration
# Dwindle layout, DMS shell, transparent foot
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    systemd.enable = true; # integrate with systemd user session

    # Portal is managed at NixOS level, not home-manager
    # This prevents HM from overwriting NIX_XDG_DESKTOP_PORTAL_DIR
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "foot";
      "$menu" = "fuzzel";

      # Monitor config - 4K at 1.5x scale for 15" display
      monitor = [ ",preferred,auto,1.5" ];

      # General appearance
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(670061ff)";
        "col.inactive_border" = "rgba(414868ff)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 20;
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 15;
          render_power = 3;
        };
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

      # Input - match niri
      input = {
        kb_layout = "gb";
        kb_variant = "colemak_dh";
        kb_options = "caps:escape";

        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          clickfinger_behavior = true; # 2-finger tap = right click
          drag_lock = false;
          disable_while_typing = true;
        };

        follow_mouse = 1;
        sensitivity = 0;
      };

      # Trackpad gestures
      gesture = [
        "3, horizontal, workspace"
        "3, up, fullscreen"
        "3, down, fullscreen"
        "4, horizontal, workspace"
        "4, down, special"
      ];

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Window rules
      windowrule = [
        "opacity 0.75 0.65, match:class foot"
      ];

      # No CSD
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      # Keybindings - Colemak-DH (mnei = hjkl)
      bind = [
        # Core actions
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $menu"
        "$mod, Q, killactive"
        "$mod SHIFT, Q, exit"
        "CTRL ALT, BackSpace, exit"
        "$mod, L, exec, swaylock"
        "$mod, V, togglefloating"
        "$mod, G, togglefloating"
        "$mod, F, fullscreen"
        "$mod, P, pseudo"
        "$mod, S, togglesplit"

        # Layout toggle (dwindle = BSP tree, master = 1+N stack)
        "$mod, T, exec, hyprctl keyword general:layout dwindle"
        "$mod SHIFT, T, exec, hyprctl keyword general:layout master"

        # Focus movement (mnei)
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

        # Scroll through workspaces
        "$mod, Page_Down, workspace, +1"
        "$mod, Page_Up, workspace, -1"

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

      # Startup - DMS starts via systemd graphical-session.target
      exec-once = [
        "gnome-keyring-daemon --start --components=secrets,pkcs11"
      ];
    };
  };

  # Hyprland-specific tools
  home.packages = with pkgs; [
    # Screenshots
    grim
    slurp

    # Screen recording
    wf-recorder

    # App launcher
    fuzzel

    # Display config
    wlr-randr
  ];
}
