{...}:
{
    imports = [
      ./dist-builds.nix
      ./fontconfig.nix
      ./gc.nix
      ./home-manager.nix
      ./internationalization.nix
      ./numlock.nix
      ./shared.nix
      ./sshd.nix
      ./users.nix
      ./virtualization.nix
      ./wifi.nix
      ./x11.nix
    ];

    # Set your time zone.
    time.timeZone = "Europe/London";

    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # globally allow unfree software, needed for drivers, etc.
    nixpkgs.config.allowUnfree = true;

    # have the system do updates regularly.
    system.autoUpgrade.enable = true;

    # Apply terminal fonts asap during boot.
    boot.earlyVconsoleSetup = true;

    services.printing.enable = true;

    networking.networkmanager = {
      enable = true;
      appendNameservers = [ "10.0.0.1" ];
    };
}
