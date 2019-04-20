{ pkgs, ... }:

let hmConfig = {

  # terminal emulator: rxvt-unicode
  programs.urxvt = {
    enable = true;
    fonts = [ "xft:Terminus:pixelsize=16" ];
    package = pkgs.rxvt_unicode-with-plugins;
    keybindings = {
      # enable vi mode
      Ctrl-Shift-P = "perl:keyboard-select:activate";
    };

    extraConfig = {
      # enable the plugin for vi mode
      perl-ext-common = "...,keyboard-select";
      # needed for transparent background
      depth = "32";
      # dark (transparent) background without eye-fucking blues.
      background = "[35]#000000";
      foreground = "White";
      color4 = "RoyalBlue";
      color12 = "RoyalBlue";
    };
  };

};
in
{
    home-manager.users = {
        dany = hmConfig;
        root = hmConfig;
    };
}
