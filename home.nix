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

  home.packages = with pkgs; [
    # fonts for terminal, etc.
    terminus_font

    # downloading from the net
    wget

    # uploading console output to pastebin
    pastebinit

    # browser
    firefox
  ];

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
#  xsession = {
#    enable = true;
#    windowManager.xmonad = {
#      enable = true;
#      config = ./xmonad/xmonad.hs;
#    };
#    profileExtra = ''
#      # bootstrap configuration, force loading.
#      ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources
#      
#      # set background image.
#      ${pkgs.feh}/bin/feh --bg-fill ~/.bg.png
#      '';
#  };

#  home.file.".bg.png".source = ./xmonad/bg.png;
#  home.file.".xinitrc".text = "exec ~/.xsession";

  # used for wallpaper: feh
  programs.feh.enable = true;

  # transparent windows: compton
  services.compton = {
    enable = true;
    blur = true;
  };
    
}
