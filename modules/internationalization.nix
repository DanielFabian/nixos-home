{...}:
let hmConfig = {
  home.keyboard = {
    layout = "gb";
    options = ["eurosign:e" "caps:swapescape" ];
  };
};
in
{
  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleUseXkbConfig = true;
    defaultLocale = "en_GB.UTF-8";
  };

  # needed for home manager to be happy
  home-manager.users = {
    dany = hmConfig;
    root = hmConfig;
  };

  # make xkbConfig happy too
  services.xserver = {
    layout = hmConfig.home.keyboard.layout;
    xkbOptions = builtins.concatStringsSep ", " hmConfig.home.keyboard.options;
  };
}
