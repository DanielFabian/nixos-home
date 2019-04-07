{
  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "uk";
    defaultLocale = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.layout = "gb";
  services.xserver.xkbOptions = "eurosign:e";
}