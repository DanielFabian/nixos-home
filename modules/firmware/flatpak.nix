# Flatpak - Rolling apps layer (FHS sandbox)
# Uses nix-flatpak for declarative management
{ config, pkgs, ... }:

{
  # XDG portals are required for Flatpak apps (incl. VS Code) to open URLs,
  # show file pickers, etc. Ensure a backend that supports OpenURI.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common = {
      default = [ "gtk" ];
      # Be explicit: route the OpenURI interface to the GTK backend.
      # (The key is the *impl* interface name; see portals.conf(5)).
      "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
    };
  };

  # Make sure portal + backends are discoverable for D-Bus activation.
  # (Without this, org.freedesktop.portal.Desktop may start without OpenURI.)
  services.dbus.packages = with pkgs; [
    xdg-desktop-portal
    xdg-desktop-portal-gtk
  ];

  # Enable flatpak daemon
  services.flatpak = {
    enable = true;

    # Flathub remote (auto-configured by nix-flatpak)
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    # Auto-update weekly
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    # Declarative flatpak packages
    packages = [
      # VS Code - needs portal secrets, works better as flatpak
      "com.visualstudio.code"

      # Communication
      "com.discordapp.Discord"

      # Browsers
      "com.microsoft.Edge"
    ];

    # Overrides for VS Code to access Nix-managed tools
    overrides = {
      global = {
        # Force Wayland
        Context.sockets = [
          "wayland"
          "!x11"
          "!fallback-x11"
        ];
      };

      "com.visualstudio.code".Context = {
        filesystems = [
          "xdg-config/git:ro" # Git config
          "/run/current-system/sw/bin:ro" # Nix-managed binaries
          "home" # Home dir access
        ];
        sockets = [
          "gpg-agent" # GPG signing
          "ssh-auth" # SSH agent
        ];
      };
    };
  };

  # System-wide flatpak management GUI (optional)
  environment.systemPackages = with pkgs; [
    gnome-software # GUI for browsing/installing flatpaks
  ];
}
