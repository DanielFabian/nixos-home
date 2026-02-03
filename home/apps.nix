# Rolling apps - from unstable or Flatpak
{ config, pkgs, ... }:

{
  # CLI tools from unstable
  home.packages = with pkgs.unstable; [
    # Communication (Flatpak probably better for these, but here for reference)
    # discord
    # slack

    # Media
    # spotify  # use flatpak
    mpv

    # File management
    yazi # terminal file manager (modern ranger/vifm)

    # System monitoring
    btop

    # Development - general tools
    jq
    yq
    httpie

    # Docker/container tools
    dive # explore docker images
    lazydocker

    # Cloud CLI tools
    # azure-cli  # use devcontainer for cloud stuff

    # Misc
    neofetch
    fastfetch
  ];

  # VS Code now managed via flatpak (see modules/firmware/flatpak.nix)
  # Flatpak VS Code uses portal secrets properly

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
