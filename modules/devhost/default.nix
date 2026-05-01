# Cattle invariants shared by every devhost flavour.
#
# Per-host modules (hosts/devhost-hyperv, hosts/devhost-mac) import this and
# add only what is genuinely substrate-specific: kernel modules, disk paths,
# bootloader, hostPlatform, and any virtualization-stack quirks.
#
# Philosophy: cattle, not pets. The OS disk is regenerable from this flake.
# Only /home (on a second virtual disk, label "workspace") survives re-imaging.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.devhost;
in
{
  imports = [
    ./wipe.nix
    ./nix-share.nix
    ../firmware/docker.nix
  ];

  options.devhost = {
    autoUpgradeFlake = lib.mkOption {
      type = lib.types.str;
      description = ''
        Flake reference (URL#attr) the system tracks for auto-upgrades.
        e.g. "github:DanielFabian/sovereign-codespaces#devhost-hyperv".
      '';
    };
  };

  config = {
    networking.hostName = lib.mkDefault "devhost";
    networking.useDHCP = lib.mkDefault true;
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [
        "docker0"
        "podman0"
      ];
    };

    time.timeZone = lib.mkDefault "Europe/London";

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

    # Nix: flakes + content-addressed store shared with devcontainers.
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
      # GC is manual on devhost — running it while a container resolves
      # store paths is a known footgun. Re-enable once usage patterns settle.
      gc.automatic = false;
    };

    # Auto-upgrade from this flake. Per-variant attr provided via the
    # `devhost.autoUpgradeFlake` option set in the per-host module.
    system.autoUpgrade = {
      enable = true;
      flake = cfg.autoUpgradeFlake;
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

    # nix-ld: provides a dynamic loader at /lib64/ld-linux-x86-64.so.2 so
    # prebuilt glibc binaries run unmodified. Required for VS Code Remote-SSH
    # (which drops a prebuilt node server into ~/.vscode-server) and for
    # devcontainer tooling that bootstraps non-Nix binaries.
    programs.nix-ld.enable = true;

    # SSH — the whole point of the machine.
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

    # User — defined inline (not via modules/users/dany.nix) to avoid
    # pulling desktop-oriented groups (libvirtd, plugdev, video, audio,
    # networkmanager) into the headless VM.
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
      # Incoming SSH keys — single source of truth in ./authorized-keys.nix.
      openssh.authorizedKeys.keys = (import ./authorized-keys.nix).keys;
    };
    security.sudo.wheelNeedsPassword = false;

    # First-boot workspace disk init. Formats `devhost.workspaceDevice` as
    # ext4 with label "workspace" iff it's present and has no existing
    # filesystem signature. Idempotent: subsequent boots find the label and
    # skip the mkfs.
    systemd.services.devhost-init-workspace = {
      description = "Initialize /home workspace disk on first boot";
      wantedBy = [ "local-fs-pre.target" ];
      before = [ "local-fs-pre.target" ];
      unitConfig = {
        DefaultDependencies = false;
        ConditionPathExists = cfg.workspaceDevice;
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
        # If the workspace disk already has any filesystem/LUKS/etc signature,
        # do nothing. This is what makes /home survive re-imaging.
        if blkid ${cfg.workspaceDevice} >/dev/null 2>&1; then
          echo "devhost: ${cfg.workspaceDevice} already initialized, skipping mkfs"
          exit 0
        fi
        echo "devhost: formatting ${cfg.workspaceDevice} as ext4 (label=workspace)"
        mkfs.ext4 -L workspace -F ${cfg.workspaceDevice}
      '';
    };

    # First-boot user SSH keypair + MOTD advertisement. Every re-image
    # produces a fresh key; you re-register the pubkey on GitHub. The MOTD
    # prints it so you see it immediately on first SSH login.
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
  };
}
