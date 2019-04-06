{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  # terminal emulator: rxvt-unicode
  programs.urxvt = {
    enable = true;
    fonts = [ "xft:Terminus:pixelsize=16" ];
    keybindings = {
      # allow some copy/paste
      "Shift-Control-C" = "eval:selection_to_clipboard";
      "Shift-Control-V" = "eval:paste_clipboard";
    };
    extraConfig = {
      # needed for transparent background
      depth = "32";
      # dark (transparent) background without eye-fucking blues.
      background = "[35]#000000";
      foreground = "White";
      color4 = "RoyalBlue";
      color12 = "RoyalBlue";
    };
  };

  programs.vscode.extensions =
    with pkgs.vscode-extensions;
    [
      # haskell
      justusadam.language-haskell
      # Nix
      bbenoist.Nix
    ];

  home.packages = with pkgs; [
    # fonts for terminal, etc.
    terminus_font

    # downloading from the net
    wget

    # uploading console output to pastebin
    pastebinit

    # browser
    brave

    # overview of performance
    iotop

    # launching programs from xmonad
    dmenu

    # timing processes
    time

    # screen shots
    scrot
    screenfetch

    # diffing tool
    kdiff3

    # git
#    gitkraken
  ];

  # IRC client
  programs.irssi = {
    enable = true;
    networks = {
      freenode = {
        nick = "iceypoi";
        server = {
          address = "chat.freenode.net";
          port = 6697;
          autoConnect = true;
        };
        channels = {
          nixos.autoJoin = true;
          home-manager.autoJoin = true;
          nixos-chat.autoJoin = false;
          nix-lang.autoJoin = false;
        };
      };
    };
  };

  home.keyboard = {
    layout = "gb";
    options = [ "eurosign:e" ];
  };

  # git config
  programs.git = {
    enable = true;
    userName = "Daniel Fabian";
    userEmail = "daniel.fabian@integral-it.ch";
  };

  # process viewer: htop
  programs.htop.enable = true;

  # ide: VS code
  programs.vscode.enable = true;

  # control XSession from within home-manager:
  xsession = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      config = ./xmonad/xmonad.hs;
    };
    profileExtra = ''
      # bootstrap configuration, force loading.
      ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources
      
      # set background image.
      ${pkgs.feh}/bin/feh --bg-fill ~/.bg.png

      # set numlock to on in x session.
      ${pkgs.numlockx}/bin/numlockx
      '';
  };

  home.file.".bg.png".source = ./xmonad/bg.png;
  home.file.".xinitrc".text = "exec ~/.xsession";

  # used for wallpaper: feh
  programs.feh.enable = true;

  # transparent windows: compton
  services.compton = {
    enable = true;
    blur = true;
    # fix sync issue with compton. This is probably an NVidia driver thing.
    extraOptions = ''
      xrender-sync = true;
      xrender-sync-fence = true;
      '';
  };   
}
