# Terminal emulator - foot (Wayland-native, fast, minimal)
{ config, pkgs, ... }:

{
  # Foot - lightweight Wayland terminal
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "JetBrainsMono Nerd Font:size=11";
        pad = "8x8";
      };
      
      mouse = {
        hide-when-typing = "yes";
      };

      colors = {
        # Tokyo Night palette (matches LazyVim default)
        background = "1a1b26";
        foreground = "c0caf5";
        
        regular0 = "15161e";  # black
        regular1 = "f7768e";  # red
        regular2 = "9ece6a";  # green
        regular3 = "e0af68";  # yellow
        regular4 = "7aa2f7";  # blue
        regular5 = "bb9af7";  # magenta
        regular6 = "7dcfff";  # cyan
        regular7 = "a9b1d6";  # white
        
        bright0 = "414868";
        bright1 = "f7768e";
        bright2 = "9ece6a";
        bright3 = "e0af68";
        bright4 = "7aa2f7";
        bright5 = "bb9af7";
        bright6 = "7dcfff";
        bright7 = "c0caf5";
      };
    };
  };

  # Install Nerd Fonts for icons
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
  ];

  # Font config
  fonts.fontconfig.enable = true;
}
