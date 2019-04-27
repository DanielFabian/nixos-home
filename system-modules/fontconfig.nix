{pkgs, ...}:
{
  fonts = {
    fontconfig = {
      defaultFonts = {
        monospace = [ "FuraCode Nerd Font" ];
        sansSerif = [ "Overpass" ];
      };
      useEmbeddedBitmaps = true;
    };
    fonts = with pkgs; [ overpass ];
  };

  i18n.consoleFont = "Lat2-Terminus16";
}
