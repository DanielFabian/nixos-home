{ config, pkgs, ... }:
{
  imports = [
      ./home-modules/fontconfig.nix
      ./home-modules/internationalization.nix
      ./home-modules/neovim.nix
      ./home-modules/urxvt.nix
      ./home-modules/vscode.nix
      ./home-modules/fish.nix
      ./xmonad
    ];
 # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.rofi = {
    enable = true;
    theme = "arthur";
  };

  programs.chromium = {
    enable = true;
    extensions = [
      # uBlock origin
      "cjpalhdlnbpafiamejdnhcphjbkeiagm"

      # LastPass
      "hdokiejnpimakedhajhdlcegeplioahd"

      # Toby
      "hddnkoipeenegfoeaoibdmnaalmgkpip"

      # Vimium
      "dbepggeogbaibhgnhhndojpepiihcmeb"
    ];
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

    # Azure CLI
    azure-cli

    # File manager
    vifm

    # Tool to get system info
    neofetch
  ];

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

  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 100000;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };
}
