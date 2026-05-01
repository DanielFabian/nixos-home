# Generalized auto-installing ISO environment.
#
# Per-variant installer modules (hosts/devhost-*/installer.nix) import this
# and set:
#   devhost.installer.flakeUrl  — flake to install from (URL only, no #attr)
#   devhost.installer.hostAttr  — nixosConfigurations attribute name
#   devhost.osDisk              — block device to install onto (via wipe.nix)
#
# Explicitly does NOT import modules/devhost/default.nix — the installer
# environment is its own NixOS config, separate from the system it installs.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.devhost.installer;
  diskCfg = config.devhost;
in
{
  imports = [
    ./wipe.nix
  ];

  options.devhost.installer = {
    flakeUrl = lib.mkOption {
      type = lib.types.str;
      description = ''
        Flake URL the installer pulls from, without the #attr suffix.
        e.g. "github:DanielFabian/sovereign-codespaces".
      '';
    };
    hostAttr = lib.mkOption {
      type = lib.types.str;
      description = ''
        The nixosConfigurations attribute name to install,
        e.g. "devhost-hyperv" or "devhost-mac".
      '';
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        SSH pubkeys allowed to log in to the *installer environment* as root.
        Useful for debugging a failed install. Independent of the installed
        system's authorized_keys.
      '';
    };
    ejectDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/dev/sr0";
      description = ''
        Optical/cdrom device to eject after install completes, so the VM
        doesn't reboot back into the ISO. Set to null to skip (e.g. on
        hypervisors that don't expose an eject-able cdrom).
      '';
    };
  };

  config = {
    # Allow the installer to reach into unfree if the devhost closure needs
    # it transitively. Harmless on the installer itself.
    nixpkgs.config.allowUnfree = true;

    # Flakes available inside the live environment so nixos-install --flake works.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Keyboard: same as the installed system. Useful if auto-install fails
    # and you're dropped into a live shell to debug.
    console.useXkbConfig = true;
    services.xserver.xkb = {
      model = "pc105";
      layout = "gb";
      variant = "colemak_dh";
      options = "caps:escape";
    };

    # Networking inside the installer — NetworkManager is already enabled by
    # the install-iso format; it handles DHCP on the synthetic NIC.
    networking.hostName = "devhost-installer";

    # SSH for post-mortem access if install fails. Keys only.
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };
    users.users.root.openssh.authorizedKeys.keys = cfg.authorizedKeys;

    # The auto-installer itself. Runs once the live environment is up.
    # Simple disk layout: GPT, 512M ESP, rest ext4 root with label "nixos"
    # (matching the per-host hardware-configuration.nix), then nixos-install
    # --flake, then reboot.
    systemd.services.devhost-auto-install = {
      description = "Auto-install ${cfg.hostAttr} onto ${diskCfg.osDisk}";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig = {
        ConditionPathExists = diskCfg.osDisk;
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };
      path = with pkgs; [
        util-linux
        parted
        e2fsprogs
        dosfstools
        nixos-install-tools
        nix # nixos-install shells out to `nix` for the build
        git
        openssh
        coreutils
        gnused
        eject
      ];
      script = ''
        set -eux

        # If the OS disk already has our "nixos" label, assume install ran
        # and something went wrong with the reboot — don't wipe. Operator
        # intervenes with `devhost-wipe` if a reinstall is intentional.
        if blkid -L nixos >/dev/null 2>&1; then
          echo "devhost-installer: ${diskCfg.osDisk} already has a 'nixos' labelled fs."
          echo "devhost-installer: refusing to reinstall. Wipe manually if intentional."
          exit 0
        fi

        echo "devhost-installer: partitioning ${diskCfg.osDisk}"
        # Wipe signatures so parted doesn't complain.
        wipefs -a ${diskCfg.osDisk} || true
        parted -s ${diskCfg.osDisk} -- mklabel gpt
        parted -s ${diskCfg.osDisk} -- mkpart ESP fat32 1MiB 513MiB
        parted -s ${diskCfg.osDisk} -- set 1 esp on
        parted -s ${diskCfg.osDisk} -- mkpart primary ext4 513MiB 100%

        # Let the kernel re-read the partition table and udev create symlinks
        # for the new partitions before we try to format them.
        partprobe ${diskCfg.osDisk} || true
        udevadm settle --timeout=30

        # Partition device naming: /dev/sda → /dev/sda1, but /dev/nvme0n1 →
        # /dev/nvme0n1p1. Hyper-V and Apple Virtualization both expose plain
        # sd*/vd*, so simple suffix concatenation works for our targets.
        ESP=${diskCfg.osDisk}1
        ROOT=${diskCfg.osDisk}2

        mkfs.fat  -F 32 -n BOOT  "$ESP"
        mkfs.ext4 -L   nixos    "$ROOT"

        # Same story after mkfs — by-label symlinks are created by udev
        # asynchronously. Mount by explicit path to avoid the race entirely.
        udevadm settle --timeout=30

        mkdir -p /mnt
        mount "$ROOT" /mnt
        mkdir -p /mnt/boot
        mount "$ESP" /mnt/boot

        echo "devhost-installer: nixos-install --flake ${cfg.flakeUrl}#${cfg.hostAttr}"
        nixos-install \
          --flake ${cfg.flakeUrl}#${cfg.hostAttr} \
          --no-root-password \
          --no-channel-copy

        echo "devhost-installer: install complete, ejecting media and rebooting in 10s"
        sync
        # Best-effort eject so the VM boots from disk instead of the ISO again.
        ${
          if cfg.ejectDevice == null then
            "# ejectDevice = null; skipping"
          else
            "eject ${cfg.ejectDevice} || true"
        }
        sleep 10
        systemctl reboot
      '';
    };

    # Prevent getty spam from drowning out the install log on the console.
    services.getty.helpLine = lib.mkForce ''
      devhost auto-installer running. Check `journalctl -u devhost-auto-install -f`.
      Do not remove installation media until the VM reboots on its own.
    '';

    system.stateVersion = "25.11";
  };
}
