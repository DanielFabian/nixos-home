{pkgs, ...}:
{
  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "Terminus" "DejaVu Sans Mono" "TerminessTTF Nerd Font" ];
    };
    useEmbeddedBitmaps = true;
  };

  i18n.consoleFont = "Lat2-Terminus16";
}
