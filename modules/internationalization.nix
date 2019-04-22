{
  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleUseXkbConfig = true;
    defaultLocale = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    layout = "gb";
    xkbOptions = "eurosign:e, caps:swapescape";
  };
}