# Hyprland - Wayland compositor
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Hyprland from flake for freshness
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
  };

  # XDG portal for screen sharing, file dialogs, etc
  # Note: Hyprland flake handles xdg-desktop-portal-hyprland automatically
  xdg.portal = {
    enable = true;
    # extraPortals managed by programs.hyprland when using the flake
  };

  # Recommended utilities (home-manager handles most config)
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    wl-clipboard
    wlr-randr

    # Screenshots
    grim
    slurp

    # Screen recording
    wf-recorder

    # Notification daemon
    mako

    # App launcher - wofi (wayland-native rofi alternative)
    wofi

    # Status bar (home-manager configures waybar)
    waybar

    # Qt Wayland support
    qt6.qtwayland
    libsForQt5.qt5.qtwayland

    # Network manager tray applet
    networkmanagerapplet
  ];

  # Polkit for authentication dialogs
  security.polkit.enable = true;

  # Gnome keyring for secrets
  services.gnome.gnome-keyring.enable = true;
  # Auto-unlock keyring at login via greetd
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Enable greetd display manager (lightweight, Wayland-native)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # tuigreet with session picker - shows Hyprland, Plasma, etc.
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions /run/current-system/sw/share/wayland-sessions:/run/current-system/sw/share/xsessions";
        user = "greeter";
      };
    };
  };
}
