{...}:
{
    imports = [
      ./internationalization.nix
      ./home-manager.nix
      ./users.nix
      ./fontconfig.nix
      ./numlock.nix
      ./gc.nix
      ./virtualization.nix
      ./urxvt.nix
      ./vscode.nix
      ./neovim.nix
      ./sshd.nix
      ../xmonad
    ];

    # Set your time zone.
    time.timeZone = "Europe/London";

    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "19.09"; # Did you read the comment?

    # globally allow unfree software, needed for drivers, etc.
    nixpkgs.config.allowUnfree = true;

    # have the system do updates regularly.
    system.autoUpgrade.enable = true;

    # Apply terminal fonts asap during boot.
    boot.earlyVconsoleSetup = true;

    services.printing.enable = true;
}
