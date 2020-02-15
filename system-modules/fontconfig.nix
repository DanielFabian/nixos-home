{pkgs, ...}:
{
  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "CaskaydiaCove Nerd Font" ];
    };
    useEmbeddedBitmaps = true;
  };

  console.font = "Lat2-Terminus16";
}
