{pkgs, ...}:
{
  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "Terminess Powerline" "Terminus" "DejaVu Sans Mono" ];
    };
    useEmbeddedBitmaps = true;
  };
}
