{pkgs, ...}:
{
  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "Terminess Powerline" "Terminus" "DejaVu Sans Mono" ];
    };
    useEmbeddedBitmaps = true;
  };

  i18n.consoleFont = "Lat2-Terminus16";
}
