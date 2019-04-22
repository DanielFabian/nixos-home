{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

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

    # evenote-like thingie
    nixnote2

    # adobe
    adobe-reader

    # text-based mail client
    mutt
  ];

  home.keyboard = {
    layout = "gb";
    options = [ "eurosign:e" ];
  };

  # firefox, sometimes needed
  programs.firefox = {
    enable = true;
    enableAdobeFlash = true;
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
  programs.vscode = {
    enable = true;
    userSettings = {
      "editor.lineNumbers" = "relative";
    };

    extensions =
      with pkgs.vscode-extensions;
      [
        # haskell
        justusadam.language-haskell
        # Nix
        bbenoist.Nix
        # vim key bindings
        vscodevim.vim
      ];
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 100000;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
  };

  programs.neovim = {
    enable = true;
    configure = {
      customRC = ''
        set relativenumber
        set ic
        set hls is
        '';
      packages.myVimPackages = with pkgs.vimPlugins; {
        start = [ vim-nix ];
      };
    };
    viAlias = true;
    vimAlias = true;
  };
}
