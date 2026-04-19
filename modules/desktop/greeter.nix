# Display manager / greeter
# Use COSMIC greeter (Wayland GUI) via the upstream NixOS module.
{ config, pkgs, lib, ... }:

let
  hyprlandDirectLauncher = pkgs.writeShellScriptBin "hyprland-direct" ''
    set -euo pipefail

    CACHE_DIR="$HOME/.cache/hyprland"
    ${pkgs.coreutils}/bin/mkdir -p "$CACHE_DIR"

    TS="$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
    LOGFILE="$CACHE_DIR/hyprland-direct-$TS.log"

    echo "[hyprland-direct] starting at $TS" >>"$LOGFILE"
    echo "[hyprland-direct] user=$(id -u) gid=$(id -g)" >>"$LOGFILE"
    echo "[hyprland-direct] XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR-}" >>"$LOGFILE"
    echo "[hyprland-direct] WAYLAND_DISPLAY=''${WAYLAND_DISPLAY-}" >>"$LOGFILE"
    echo "[hyprland-direct] DISPLAY=''${DISPLAY-}" >>"$LOGFILE"
    echo "[hyprland-direct] PATH=$PATH" >>"$LOGFILE"
    echo "[hyprland-direct] ---- exec start-hyprland (no nixgl) ----" >>"$LOGFILE"

    exec ${config.programs.hyprland.package}/bin/start-hyprland --no-nixgl -- >>"$LOGFILE" 2>&1
  '';

  hyprlandDesktopSession = pkgs.writeTextFile {
    name = "hyprland-session";
    passthru = {
      providedSessions = [ "hyprland-direct" ];
    };
    destination = "/share/wayland-sessions/hyprland-direct.desktop";
    text = ''
      [Desktop Entry]
      Name=Hyprland (direct)
      Comment=An intelligent dynamic tiling Wayland compositor
      Exec=${hyprlandDirectLauncher}/bin/hyprland-direct
      TryExec=${hyprlandDirectLauncher}/bin/hyprland-direct
      Type=Application
      DesktopNames=Hyprland
      Keywords=tiling;wayland;compositor;
    '';
  };
in

{
  # COSMIC greeter sets up greetd + required PAM/dbus/users internally.
  services.displayManager.cosmic-greeter.enable = true;

  # COSMIC greeter enumerates available sessions from `share/wayland-sessions`.
  # Ensure the session desktop files are present in the system closure.
  services.displayManager.sessionPackages = [
    pkgs.niri
    # Avoid Hyprland's `start-hyprland` wrapper here: it can try to exec `nixGL`
    # (not in PATH under greetd) and exit immediately, bouncing back to the greeter.
    hyprlandDesktopSession
  ];

  # NixOS does not necessarily link *all* of `/share` into the system profile.
  # COSMIC greeter expects the session desktop files to be present under:
  #   /run/current-system/sw/share/wayland-sessions
  # so we must explicitly link that subdir into the system profile.
  environment.pathsToLink = lib.mkAfter [
    "/share/wayland-sessions"
    "/share/xsessions"
  ];

  # Shared session infrastructure
  programs.dconf.enable = true; # GTK theming (dark mode preference)
  security.pam.services.swaylock = { }; # Screen locker PAM

  # Shared packages across all Wayland sessions
  environment.systemPackages = with pkgs; [
    swaylock # Screen locker
    wl-clipboard # Clipboard (used by niri + hyprland)
    seahorse # Keyring UI
    # Ensure COSMIC greeter (which scans /run/current-system/sw/share/wayland-sessions)
    # can see the direct Hyprland session entry.
    hyprlandDesktopSession
  ];
}
