# devhost - disposable NixOS dev-container host for Hyper-V
#
# Philosophy: cattle, not pets. The OS disk is regenerable from this flake.
# Only /home (on a second VHDX, label "workspace") survives re-imaging.
#
# See hosts/devhost/README-usage.md style instructions in the flake output.
{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./wipe.nix
    ../../modules/firmware/docker.nix
  ];

  networking.hostName = "devhost";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [
      "docker0"
      "podman0"
    ];
  };

  time.timeZone = "Europe/London";

  # Keyboard: ISO UK + Colemak Mod-DH, same as the physical hosts.
  # useXkbConfig makes the TTY console honor the xkb settings below.
  console = {
    useXkbConfig = true;
    earlySetup = true;
  };
  services.xserver.xkb = {
    model = "pc105";
    layout = "gb";
    variant = "colemak_dh";
    options = "caps:escape";
  };

  # Nix: flakes + content-addressed store shared with devcontainers later.
  # trusted-users lets the devcontainer bind-mount talk to the daemon.
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "dany"
        "@wheel"
      ];
    };
    # GC is manual on devhost - running it while a container resolves store
    # paths is a known footgun. Re-enable once slice B is proven out.
    gc.automatic = false;
  };

  # Auto-upgrade from this flake. Keeps the VM current without ceremony.
  system.autoUpgrade = {
    enable = true;
    flake = "github:DanielFabian/nixos-home#devhost";
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = false; # reboot on your schedule, not systemd's
  };

  # Minimal package set. This is a server, not a workstation.
  # devhost-wipe comes in via ./wipe.nix.
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    htop
    btop
    rsync
    tmux
  ];

  # SSH - the whole point of the machine.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      # Print /etc/motd on login so the freshly-generated pubkey is visible
      # without the user having to know to `cat /etc/motd`.
      PrintMotd = true;
    };
  };

  # User - define inline (not via modules/users/dany.nix) to avoid pulling
  # desktop-oriented groups (libvirtd, plugdev) that don't exist here.
  users.mutableUsers = false;
  users.users.dany = {
    isNormalUser = true;
    description = "Daniel Fabian";
    home = "/home/dany";
    shell = pkgs.bash;
    extraGroups = [
      "wheel"
      "docker"
    ];
    # Incoming SSH - workstation + mac public keys. Add yours below.
    openssh.authorizedKeys.keys = [
      ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcfIVEBJCwiZ8gTpjWEBY4PZYROBRZh5kDyzP+hQa3d europe\danfab@DESKTOP-C0PQAHF''
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOteZE3XjPTRI08LKeYKrGC/2l9MpowjRZLjtt50cpOD dany@DESKTOP-C0PQAHF"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # First-boot workspace disk init. Formats /dev/sdb as ext4 with label
  # "workspace" iff it's present and has no existing filesystem signature.
  # Idempotent: subsequent boots find the label and skip the mkfs.
  systemd.services.devhost-init-workspace = {
    description = "Initialize /home workspace disk on first boot";
    wantedBy = [ "local-fs-pre.target" ];
    before = [ "local-fs-pre.target" ];
    unitConfig = {
      DefaultDependencies = false;
      ConditionPathExists = "/dev/sdb";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [
      util-linux
      e2fsprogs
    ];
    script = ''
      # If sdb already has any filesystem/LUKS/etc signature, do nothing.
      if blkid /dev/sdb >/dev/null 2>&1; then
        echo "devhost: /dev/sdb already initialized, skipping mkfs"
        exit 0
      fi
      echo "devhost: formatting /dev/sdb as ext4 (label=workspace)"
      mkfs.ext4 -L workspace -F /dev/sdb
    '';
  };

  # First-boot user SSH keypair + MOTD advertisement. Every re-image produces
  # a fresh key; you re-register the pubkey on GitHub. The MOTD prints it so
  # you see it immediately on first SSH login.
  systemd.services.devhost-user-ssh-key = {
    description = "Generate dany's SSH keypair and publish pubkey via MOTD";
    wantedBy = [ "multi-user.target" ];
    after = [
      "home.mount"
      "local-fs.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [
      openssh
      coreutils
      util-linux # runuser
    ];
    script = ''
      set -eu
      SSHDIR=/home/dany/.ssh
      KEY=$SSHDIR/id_ed25519
      install -d -o dany -g users -m 0700 "$SSHDIR"
      if [ ! -f "$KEY" ]; then
        runuser -u dany -- ssh-keygen -t ed25519 -f "$KEY" -N "" -C "dany@devhost"
      fi
      {
        echo ""
        echo "=== devhost: user SSH public key (register on GitHub) ==="
        cat "$KEY.pub"
        echo "=========================================================="
        echo ""
      } > /etc/motd
    '';
  };

  system.stateVersion = "25.11";
}
