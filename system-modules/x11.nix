{pkgs, ...}:
{
  xdg.icons.enable = true;
  environment.systemPackages = [ pkgs.gnome3.adwaita-icon-theme pkgs.gnome3.gnome-themes-extra ];
  qt5 = { 
    enable = true;
    platformTheme = "gnome";
    style = "adwaita";
  };

  gtk.iconCache.enable = true;

  # Enable the X server.
  services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
      desktopManager = {
          xterm.enable = false;
      };
  };
}
