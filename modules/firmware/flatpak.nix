# Flatpak - Rolling apps layer (FHS sandbox)
# Uses nix-flatpak for declarative management
{ config, pkgs, ... }:

{
  # XDG portals - Plasma desktop handles this, just ensure xdg-open uses portal
  xdg.portal.xdgOpenUsePortal = true;

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
      # Communication
      "com.discordapp.Discord"

      # Browsers
      "com.microsoft.Edge"
    ];

    # Overrides for flatpak apps
    overrides = {
      global = {
        # Force Wayland
        Context.sockets = [
          "wayland"
          "!x11"
          "!fallback-x11"
        ];
      };
    };
  };

  # System-wide flatpak management GUI (optional)
  environment.systemPackages = with pkgs; [
    gnome-software # GUI for browsing/installing flatpaks
  ];
}
