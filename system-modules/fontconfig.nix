{pkgs, ...}:
{
  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "Terminus" "DejaVu Sans Mono" "TerminessTTF Nerd Font" ];
    };
    useEmbeddedBitmaps = true;
  };

  console.font = "Lat2-Terminus16";
}
