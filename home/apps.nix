# Rolling apps - from unstable or Flatpak
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Mutable VS Code: FHS-wrapped, self-updating binary
  # VS Code + Copilot release weekly in lockstep. Nix can't keep up.
  # Solution: Nix provides the library substrate, VS Code manages itself.
  vscode-mutable = pkgs.buildFHSEnv {
    name = "code";
    version = "mutable";

    targetPkgs =
      pkgs: with pkgs; [
        # Core
        glibc

        # Electron runtime deps
        glib
        nspr
        nss
        dbus
        at-spi2-atk
        cups
        expat
        libxkbcommon
        xorg.libX11
        xorg.libxcb
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        cairo
        pango
        alsa-lib
        libgbm
        udev

        # Extension runtime deps
        curl
        icu
        libunwind
        libuuid
        openssl
        zlib
        krb5 # mono
        fontconfig
        libsecret

        # Wayland
        wayland
        libglvnd

        # Dev tooling (git, etc. visible inside FHS)
        git
      ];

    extraBwrapArgs = [
      "--bind-try /etc/nixos/ /etc/nixos/"
      "--ro-bind-try /etc/xdg/ /etc/xdg/"
    ];

    runScript = pkgs.writeShellScript "vscode-mutable-launch" ''
      VSCODE_DIR="$HOME/.local/share/vscode-mutable"
      VSCODE_BIN="$VSCODE_DIR/code"

      if [[ ! -x "$VSCODE_BIN" ]]; then
        echo "VS Code not found, downloading latest stable..."
        mkdir -p "$VSCODE_DIR"
        ${pkgs.curl}/bin/curl -fSL \
          "https://update.code.visualstudio.com/latest/linux-x64/stable" \
          | ${pkgs.gnutar}/bin/tar xz -C "$VSCODE_DIR" --strip-components=1
      fi

      exec "$VSCODE_BIN" "$@"
    '';

    dieWithParent = false;

    extraInstallCommands = ''
      mkdir -p "$out/share/applications"
      cat > "$out/share/applications/code-mutable.desktop" <<EOF
      [Desktop Entry]
      Name=Visual Studio Code
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=$out/bin/code %F
      Icon=vscode
      Type=Application
      StartupNotify=true
      StartupWMClass=Code
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;
      EOF
    '';
  };
in
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
    ]
    ++ [
      # VS Code - mutable, self-updating (not from nixpkgs)
      vscode-mutable
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
