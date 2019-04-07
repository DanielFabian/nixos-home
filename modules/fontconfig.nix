# we must set terminus, because gitkraken otherwise uses other fonts.
{
  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "Terminus" "DejaVu Sans Mono" ];
    };
  };
}