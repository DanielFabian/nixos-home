{pkgs, config, ...}:
let hmConfig = config.home-manager.users.dany;
in
{
  # Select internationalisation properties.
  i18n = {
    # consoleFont = "${pkgs.powerline-fonts}/share/fonts/psf/ter-powerline-v16n.psf.gz";
    consoleFont = "Lat2-Terminus16";
    consoleUseXkbConfig = true;
    defaultLocale = "en_GB.UTF-8";
  };

  # make xkbConfig happy too
  services.xserver = {
    layout = hmConfig.home.keyboard.layout;
    xkbOptions = builtins.concatStringsSep ", " hmConfig.home.keyboard.options;
  };
}
