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

  programs.rofi = {
    enable = true;
    theme = "arthur";
  };

  home.packages = with pkgs; [
    # downloading from the net
    wget

    # uploading console output to pastebin
    pastebinit

    # browser
    brave

    # overview of performance
    iotop

    # timing processes
    time

    # diffing tool
    kdiff3

    # irc client
    weechat

    # git
    gitkraken

    # text-based browser
    lynx
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

  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 100000;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
  };

  programs.neovim = {
    enable = true;
  };
}
