# `devhost-wipe` — shared ceremony for resetting the host.
#
# Imported by both the installed cattle layer (modules/devhost/default.nix)
# and the installer environment (modules/devhost/installer.nix), so the same
# command is available in both. The disks are parameterized via
# `devhost.osDisk` / `devhost.workspaceDevice` so the same module works on
# Hyper-V (sd*) and Apple Virtualization (vd*).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.devhost;
in
{
  options.devhost = {
    osDisk = lib.mkOption {
      type = lib.types.str;
      default = "/dev/sda";
      description = ''
        Block device that holds the OS image. Hyper-V Gen2 presents disks as
        /dev/sd*; Apple Virtualization presents virtio-blk as /dev/vd*.
      '';
    };
    workspaceDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/sdb";
      description = ''
        Second block device used as the /home workspace disk. Formatted on
        first boot by devhost-init-workspace.service iff it has no signature.
      '';
    };
  };

  config.environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "devhost-wipe";
      runtimeInputs = with pkgs; [
        util-linux
        coreutils
      ];
      text = ''
        # Reset devhost by clearing disk signatures and rebooting.
        # On next boot the installer ISO (if attached) will re-install cleanly;
        # if no ISO is attached the VM halts at firmware — you attach the ISO
        # and power-cycle. On an already-running installed system, the in-memory
        # root FS keeps working until reboot, so this command returns normally
        # and reboot is the explicit final act.
        #
        # Scope:
        #   (default)    wipe OS disk only (${cfg.osDisk}). /home survives.
        #   --workspace  additionally wipe ${cfg.workspaceDevice} — you lose clones.
        #   --no-reboot  do the wipe but don't reboot. For testing.

        wipe_workspace=0
        do_reboot=1
        for arg in "$@"; do
          case "$arg" in
            --workspace)  wipe_workspace=1 ;;
            --no-reboot)  do_reboot=0 ;;
            -h|--help)
              echo "Usage: devhost-wipe [--workspace] [--no-reboot]"
              exit 0
              ;;
            *)
              echo "devhost-wipe: unknown argument: $arg" >&2
              exit 64
              ;;
          esac
        done

        if [[ $EUID -ne 0 ]]; then
          echo "devhost-wipe: must be run as root (use sudo)" >&2
          exit 1
        fi

        echo "devhost-wipe: this will make the VM unbootable until re-installed."
        echo "devhost-wipe: OS disk  = ${cfg.osDisk} (WILL be wiped)"
        if [[ $wipe_workspace -eq 1 ]]; then
          echo "devhost-wipe: /home    = ${cfg.workspaceDevice} (WILL be wiped)"
        else
          echo "devhost-wipe: /home    = ${cfg.workspaceDevice} (preserved)"
        fi
        read -r -p "Type 'wipe' to proceed: " confirm
        if [[ "$confirm" != "wipe" ]]; then
          echo "devhost-wipe: aborted."
          exit 1
        fi

        echo "devhost-wipe: clearing ${cfg.osDisk} signatures"
        wipefs --all --force ${cfg.osDisk} || true
        dd if=/dev/zero of=${cfg.osDisk} bs=1M count=1 conv=notrunc 2>/dev/null || true

        if [[ $wipe_workspace -eq 1 ]]; then
          echo "devhost-wipe: clearing ${cfg.workspaceDevice} signatures"
          wipefs --all --force ${cfg.workspaceDevice} || true
          dd if=/dev/zero of=${cfg.workspaceDevice} bs=1M count=1 conv=notrunc 2>/dev/null || true
        fi

        sync
        if [[ $do_reboot -eq 1 ]]; then
          echo "devhost-wipe: rebooting in 5s"
          sleep 5
          systemctl reboot
        else
          echo "devhost-wipe: done (reboot skipped)."
        fi
      '';
    })
  ];
}
