# Steam - Gaming platform
# Requires NixOS-level config for 32-bit libs, controller support, etc.
{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true;

    # Wayland support via extest
    extest.enable = true;

    # Enable gamescope for per-game scaling/FSR
    gamescopeSession.enable = true;

    # Proton-GE for better Windows game compatibility
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    # Extra tools in Steam environment
    extraPackages = with pkgs; [
      gamescope
      mangohud # FPS overlay
    ];
  };

  # Gamemode - CPU governor optimization for gaming
  programs.gamemode.enable = true;

  # Open firewall for Steam Remote Play / local network discovery
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.localNetworkGameTransfers.openFirewall = true;

  # Enable 32-bit support for games
  hardware.graphics.enable32Bit = true;
  hardware.pulseaudio.support32Bit = true;
}
