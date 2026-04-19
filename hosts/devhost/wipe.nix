# `devhost-wipe` — shared ceremony for resetting the host.
#
# Imported by both hosts/devhost/default.nix (installed system) and
# hosts/devhost/installer.nix (live installer ISO), so the same command
# is available in both environments.
{ pkgs, ... }:

{
  environment.systemPackages = [
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
        #   (default)    wipe OS disk only (/dev/sda). /home on /dev/sdb survives.
        #   --workspace  additionally wipe /dev/sdb (workspace) — you lose clones.
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
        echo "devhost-wipe: OS disk  = /dev/sda (WILL be wiped)"
        if [[ $wipe_workspace -eq 1 ]]; then
          echo "devhost-wipe: /home    = /dev/sdb (WILL be wiped)"
        else
          echo "devhost-wipe: /home    = /dev/sdb (preserved)"
        fi
        read -r -p "Type 'wipe' to proceed: " confirm
        if [[ "$confirm" != "wipe" ]]; then
          echo "devhost-wipe: aborted."
          exit 1
        fi

        echo "devhost-wipe: clearing /dev/sda signatures"
        wipefs --all --force /dev/sda || true
        dd if=/dev/zero of=/dev/sda bs=1M count=1 conv=notrunc 2>/dev/null || true

        if [[ $wipe_workspace -eq 1 ]]; then
          echo "devhost-wipe: clearing /dev/sdb signatures"
          wipefs --all --force /dev/sdb || true
          dd if=/dev/zero of=/dev/sdb bs=1M count=1 conv=notrunc 2>/dev/null || true
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
