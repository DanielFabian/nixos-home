{pkgs, ...}:
{
  home.packages = with pkgs; [
    # fonts for terminal, etc.
    terminus_font
    terminus_font_ttf
    powerline-fonts
  ];
}
