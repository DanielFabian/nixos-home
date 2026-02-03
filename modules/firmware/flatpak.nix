# Flatpak - Rolling apps layer (FHS sandbox)
# Uses nix-flatpak for declarative management
{ config, pkgs, ... }:

{
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

  # XDG portal improvements for FHS apps
  xdg.portal.xdgOpenUsePortal = true;

  # System-wide flatpak management GUI (optional)
  environment.systemPackages = with pkgs; [
    gnome-software # GUI for browsing/installing flatpaks
  ];
}
