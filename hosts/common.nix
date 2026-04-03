# Common configuration shared across all hosts
{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ../modules/firmware/boot.nix
    ../modules/firmware/docker.nix
    ../modules/firmware/networking.nix
    ../modules/firmware/flatpak.nix
    ../modules/desktop/hyprland.nix
    ../modules/desktop/cosmic.nix
    ../modules/desktop/greeter.nix
    ../modules/desktop/niri.nix
    ../modules/users/dany.nix
  ];

  # Firmware philosophy: set once, forget
  time.timeZone = "Europe/London";

  # Keyboard: ISO UK + Colemak Mod-DH
  services.xserver.xkb = {
    model = "pc105";
    layout = "gb";
    variant = "colemak_dh";
    options = "caps:escape";
  };

  console = {
    earlySetup = true;
    useXkbConfig = true;
  };

  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Firmware packages - stable, boring, essential
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    btop
    cryptsetup
    pciutils
    usbutils
    lshw
    iproute2
    dnsutils
    sbctl
  ];

  # Printing
  services.printing.enable = true;

  # Sound - pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;

  system.stateVersion = "25.11";
}
