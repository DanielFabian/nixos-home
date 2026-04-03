# Rolling apps - from unstable or Flatpak
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # CLI tools from unstable
  home.packages =
    with pkgs.unstable;
    [
      # Required for local tooling (MCP server, scripts)
      nodejs_22

      # Media
      mpv

    # File management
    yazi

    # System monitoring
    btop

    # Development - general tools
    jq
    yq
    httpie

    # Docker/container tools
    dive
    lazydocker

    # Misc
    fastfetch
  ];

  # Default applications (for xdg-open, portals, etc.)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Web browser
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];

      # Email (if needed later)
      # "x-scheme-handler/mailto" = "thunderbird.desktop";
    };
  };

  # Browser - Firefox from unstable
  programs.firefox = {
    enable = true;
    package = pkgs.unstable.firefox;
    # profiles.default = {
    #   settings = {
    #     # Privacy settings, etc
    #   };
    # };
  };

  # Flatpak for apps that really want FHS
  # System-level flatpak is enabled in firmware, this is user config
  # flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  # flatpak install flathub com.spotify.Client
  # flatpak install flathub com.discordapp.Discord
  # etc.
}
