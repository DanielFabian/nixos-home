{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.urxvt = {
    enable = true;
    fonts = [ "xft:Terminus:pixelsize=16" ];
    keybindings = {
      "Shift-Control-C" = "eval:selection_to_clipboard";
      "Shift-Control-V" = "eval:paste_clipboard";
    };
    extraConfig = {
      background = "[35]#000000";
      foreground = "White";
      color4 = "RoyalBlue";
      color12 = "RoyalBlue";
    };
  };

  home.packages = [
    pkgs.terminus_font
    pkgs.wget
    pkgs.pastebinit
  ];

  programs.git = {
    enable = true;
    userName = "Daniel Fabian";
    userEmail = "daniel.fabian@integral-it.ch";
  };

  programs.htop.enable = true;
  programs.vscode.enable = true;

}
