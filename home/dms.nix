# DankMaterialShell - Quickshell-based desktop shell for niri
# https://danklinux.com/docs/dankmaterialshell/nixos-flake
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    # Note: niri integration module requires niri-flake's home-manager module
    # We use system-level niri from nixpkgs, so skip the DMS niri module
  ];

  programs.dank-material-shell = {
    enable = true;

    # Systemd service for auto-start
    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableCalendarEvents = true; # Calendar integration

    # Use dgop from flake (not in stable nixpkgs)
    dgop.package = inputs.dgop.packages.${pkgs.system}.default;
  };
}
