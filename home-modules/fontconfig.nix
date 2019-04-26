{pkgs, fetchurl, ...}:
let cfgName = "50-enable-terminess-powerline.conf";
in
{
  # this is needed to allow terminess powerline
  xdg.configFile."fontconfig/conf.d/${cfgName}".text = ''
<?xml version='1.0'?>
<!DOCCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <selectfont>
    <acceptfont>
      <pattern>
        <patelt name="family"><string>terminess powerline</string></patelt>
      </pattern>
    </acceptfont>
  </selectfont>
</fontconfig>
   ''; 

  home.packages = with pkgs; [
    # fonts for terminal, etc.
    terminus_font
    terminus_font_ttf
    powerline-fonts
  ];
}
