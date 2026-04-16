# devhost installer ISO configuration.
#
# Produces an auto-installing ISO: boots into minimal NixOS, wipes /dev/sda,
# writes a fresh devhost install, reboots. Zero prompts. Re-imaging cost
# is "insert ISO, power on, wait, remove ISO" — same ceremony as VHDX.
#
# Explicitly does NOT import hosts/devhost/default.nix — the installer
# environment is its own NixOS config, separate from the system it installs.
{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

let
  # The flake URL the installer pulls from. If you fork, change this.
  flakeUrl = "github:DanielFabian/nixos-home";
  hostAttr = "devhost";

  # Pubkeys allowed to SSH into the *installer environment* (optional — useful
  # for debugging a failed install). Same keys as the installed system.
  installerAuthorizedKeys = [
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcfIVEBJCwiZ8gTpjWEBY4PZYROBRZh5kDyzP+hQa3d europe\danfab@DESKTOP-C0PQAHF''
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOteZE3XjPTRI08LKeYKrGC/2l9MpowjRZLjtt50cpOD dany@DESKTOP-C0PQAHF"
  ];
in
{
  imports = [
    ./wipe.nix
  ];

  # Allow the installer to reach into unstable/unfree if the devhost closure
  # needs it transitively. Harmless on the installer itself.
  nixpkgs.config.allowUnfree = true;

  # Flakes available inside the live environment so nixos-install --flake works.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Keyboard: Colemak Mod-DH on UK ISO, caps→escape. Match the installed
  # system so the muscle memory works even at the installer's login prompt
  # (useful if auto-install fails and you need to debug).
  console.useXkbConfig = true;
  services.xserver.xkb = {
    model = "pc105";
    layout = "gb";
    variant = "colemak_dh";
    options = "caps:escape";
  };

  # Networking inside the installer — NetworkManager is already enabled by
  # the install-iso format; it handles DHCP on Hyper-V's synthetic NIC.
  networking.hostName = "devhost-installer";

  # SSH for post-mortem access if install fails. Keys only.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = installerAuthorizedKeys;

  # The auto-installer itself. Runs once the live environment is up.
  # We keep it simple: GPT, 512M ESP, rest ext4 root with label "nixos"
  # (matching hosts/devhost/hardware-configuration.nix fileSystems."/"),
  # then nixos-install --flake, then reboot.
  systemd.services.devhost-auto-install = {
    description = "Auto-install devhost onto /dev/sda";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig = {
      # Only run if /dev/sda exists and has no nixos label yet.
      ConditionPathExists = "/dev/sda";
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
      nix            # nixos-install shells out to `nix` for the build
      git
      openssh
      coreutils
      gnused
      eject
    ];
    script = ''
      set -eux

      # If /dev/sda already has our "nixos" label, assume install ran and
      # something went wrong with the reboot — don't wipe. Operator intervenes.
      if blkid -L nixos >/dev/null 2>&1; then
        echo "devhost-installer: /dev/sda already has a 'nixos' labelled fs."
        echo "devhost-installer: refusing to reinstall. Wipe manually if intentional."
        exit 0
      fi

      echo "devhost-installer: partitioning /dev/sda"
      # Wipe signatures so parted doesn't complain.
      wipefs -a /dev/sda || true
      parted -s /dev/sda -- mklabel gpt
      parted -s /dev/sda -- mkpart ESP fat32 1MiB 513MiB
      parted -s /dev/sda -- set 1 esp on
      parted -s /dev/sda -- mkpart primary ext4 513MiB 100%

      # Let the kernel re-read the partition table and udev create symlinks
      # for the new partitions before we try to format them.
      partprobe /dev/sda || true
      udevadm settle --timeout=30

      mkfs.fat  -F 32 -n BOOT  /dev/sda1
      mkfs.ext4 -L   nixos    /dev/sda2

      # Same story after mkfs — the by-label symlinks are created by udev
      # asynchronously. Mount by explicit path to avoid the race entirely.
      udevadm settle --timeout=30

      mkdir -p /mnt
      mount /dev/sda2 /mnt
      mkdir -p /mnt/boot
      mount /dev/sda1 /mnt/boot

      echo "devhost-installer: nixos-install --flake ${flakeUrl}#${hostAttr}"
      nixos-install \
        --flake ${flakeUrl}#${hostAttr} \
        --no-root-password \
        --no-channel-copy

      echo "devhost-installer: install complete, ejecting media and rebooting in 10s"
      sync
      # Best-effort eject so the VM boots from disk instead of the ISO again.
      # On Hyper-V this detaches the DVD drive.
      eject /dev/sr0 || true
      sleep 10
      systemctl reboot
    '';
  };

  # Prevent getty spam from drowning out our install log on the console.
  services.getty.helpLine = lib.mkForce ''
    devhost auto-installer running. Check `journalctl -u devhost-auto-install -f`.
    Do not remove installation media until the VM reboots on its own.
  '';

  system.stateVersion = "25.11";
}
