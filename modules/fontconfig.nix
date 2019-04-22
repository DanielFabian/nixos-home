{pkgs, ...}:
let hmConfig = {
  home.packages = with pkgs; [
    # fonts for terminal, etc.
    terminus_font
    terminus_font_ttf
    powerline-fonts
  ];
};
in
# we must set terminus, because gitkraken otherwise uses other fonts.
{
  home-manager.users = {
    dany = hmConfig;
    root = hmConfig;
  };
  
  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "Terminess Powerline" "Terminus" "DejaVu Sans Mono" ];
    };
    useEmbeddedBitmaps = true;
  };
}