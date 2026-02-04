# Wayland session plumbing - the "trait" that compositor modules implement
#
# Provides: portals, secrets, polkit, clipboard, env vars
# Requires: compositor module to set compositor.* and portals.screencast
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.firmware.session;
in
{
  options.firmware.session = {
    enable = lib.mkEnableOption "Wayland session with proper portal plumbing";

    # === Compositor (must be set by implementor) ===
    compositor = {
      package = lib.mkOption {
        type = lib.types.package;
        description = "The compositor package (niri, hyprland, sway, etc.)";
      };

      sessionName = lib.mkOption {
        type = lib.types.str;
        description = "Value for XDG_CURRENT_DESKTOP and session file";
        example = "niri";
      };

      sessionCmd = lib.mkOption {
        type = lib.types.str;
        description = "Command to launch the compositor";
        example = "niri-session";
      };
    };

    # === Portals ===
    portals = {
      screencast = lib.mkOption {
        type = lib.types.package;
        description = "Screencast portal (compositor-specific: portal-wlr, portal-hyprland)";
      };
      # fileChooser and openUri are always portal-gtk, not configurable
    };

    # === Overrideable defaults ===
    polkitAgent = lib.mkOption {
      type = lib.types.package;
      default = pkgs.polkit_gnome;
      description = "Polkit authentication agent";
    };

    terminal = lib.mkOption {
      type = lib.types.package;
      default = pkgs.foot;
      description = "Default terminal. Exposed as $TERMINAL.";
    };

    launcher = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fuzzel;
      description = "App launcher. Exposed as $LAUNCHER.";
    };

    locker = lib.mkOption {
      type = lib.types.package;
      default = pkgs.swaylock;
      description = "Screen locker. Exposed as $LOCKER.";
    };
  };

  config = lib.mkIf cfg.enable {
    # === Login manager: greetd ===
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = cfg.compositor.sessionCmd;
          user = "dany"; # TODO: make configurable
        };
      };
    };

    # === XDG Portals ===
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk # FileChooser, OpenURI
        cfg.portals.screencast # Screencast (compositor-specific)
      ];
      # Explicit routing - no guessing from XDG_CURRENT_DESKTOP
      config.common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ cfg.compositor.sessionName ];
        "org.freedesktop.impl.portal.Screenshot" = [ cfg.compositor.sessionName ];
      };
    };

    # === Secrets: gnome-keyring ===
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;

    # === Polkit ===
    security.polkit.enable = true;

    # === Screen locker PAM ===
    security.pam.services.swaylock = { };

    # === Environment variables ===
    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = cfg.compositor.sessionName;
      TERMINAL = lib.getExe cfg.terminal;
      LAUNCHER = lib.getExe cfg.launcher;
      LOCKER = lib.getExe cfg.locker;
      # Hint to Qt/GTK for Wayland
      QT_QPA_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      # For Firefox Wayland
      MOZ_ENABLE_WAYLAND = "1";
    };

    # === System packages ===
    environment.systemPackages = [
      # Compositor
      cfg.compositor.package

      # Session essentials
      cfg.terminal
      cfg.launcher
      cfg.locker
      cfg.polkitAgent

      # Clipboard
      pkgs.wl-clipboard

      # Qt Wayland support
      pkgs.qt6.qtwayland
      pkgs.libsForQt5.qt5.qtwayland
    ];

    # === Polkit agent autostart ===
    # Runs as a systemd user service so it's ready for sudo prompts
    systemd.user.services.polkit-agent = {
      description = "Polkit authentication agent";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.polkitAgent}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
