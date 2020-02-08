{pkgs, config, ...}:
let hmConfig = config.home-manager.users.dany;
in
{
  # Select internationalisation properties.
  console.useXkbConfig = true;
  i18n.defaultLocale = "en_GB.UTF-8";

  # make xkbConfig happy too
  services = {
    xserver = {
      layout = hmConfig.home.keyboard.layout;
      xkbOptions = builtins.concatStringsSep ", " hmConfig.home.keyboard.options;
    };

    # remap caps lock and escape so that we can use vim key bindings globally.
    udev.extraHwdb = ''
      # Razer BlackWidow Chroma
      evdev:input:b0003v1532p0203*
       KEYBOARD_KEY_70029=capslock
       KEYBOARD_KEY_70039=esc
      
      # External Keyboard for Laptop
      evdev:input:b0003v145Fp01E7*
       KEYBOARD_KEY_70029=capslock
       KEYBOARD_KEY_70039=esc
      '';
    };
}
