{ pkgs, ... }:

let hmConfig = {

  # terminal emulator: rxvt-unicode
  programs.urxvt = {
    enable = true;
    fonts = [ "xft:Terminus:pixelsize=16" ];
    package = pkgs.rxvt_unicode-with-plugins;
    keybindings = {
      # enable vi mode
      M-Escape = "perl:keyboard-select:activate";
      Shift-Control-C = "eval:selection_to_clipboard";
      Shift-Control-V = "eval:paste_clipboard";
    };

    extraConfig = {
      # enable the plugin for vi mode
      perl-ext-common = "...,keyboard-select";
      # make sure, we copy to clipboard, too
      "keyboard-select.clipboard" = "true";
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
