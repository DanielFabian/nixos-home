{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.urxvt.enable = true;
  programs.urxvt.fonts = [ "xft:Terminus:pixelsize=12" ];
  programs.urxvt.keybindings = {
    "Shift-Control-C" = "eval:selection_to_clipboard";
    "Shift-Control-V" = "eval:paste_clipboard";
  };
  programs.urxvt.extraConfig = {
    background = "[35]#000000";
    foreground = "White";
  };

  home.packages = [
    pkgs.terminus_font
  ];

  programs.git = {
    enable = true;
    userName = "Daniel Fabian";
    userEmail = "daniel.fabian@integral-it.ch";
  };
}
