# Snapshot automation with sanoid
{ config, pkgs, ... }:

{
  # Sanoid for snapshot management
  services.sanoid = {
    enable = true;
    
    datasets = {
      # Root filesystem - moderate retention
      "rpool/local/root" = {
        autosnap = true;
        autoprune = true;
        frequently = 6;    # every 15 min, keep 6 (1.5 hours)
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 0;
      };

      # Home - aggressive retention (your uncommitted code lives here)
      "rpool/safe/home" = {
        autosnap = true;
        autoprune = true;
        frequently = 12;   # every 15 min, keep 12 (3 hours of "oh shit" buffer)
        hourly = 48;       # 2 days of hourly
        daily = 30;
        weekly = 8;
        monthly = 3;
      };

      # Persist - same as home
      "rpool/safe/persist" = {
        autosnap = true;
        autoprune = true;
        frequently = 12;
        hourly = 48;
        daily = 30;
        weekly = 8;
        monthly = 3;
      };

      # Nix store - light retention (can always rebuild)
      "rpool/local/nix" = {
        autosnap = true;
        autoprune = true;
        frequently = 0;
        hourly = 6;
        daily = 7;
        weekly = 0;
        monthly = 0;
      };
    };
  };

  # Snapshot before nixos-rebuild
  system.activationScripts.pre-rebuild-snapshot = ''
    if command -v zfs &> /dev/null; then
      ${pkgs.zfs}/bin/zfs snapshot rpool/local/root@pre-rebuild-$(date +%Y%m%d-%H%M%S) || true
    fi
  '';

  # Syncoid for backups to TrueNAS (configure destination later)
  # services.syncoid = {
  #   enable = true;
  #   interval = "daily";
  #   commands."rpool/safe" = {
  #     target = "truenas.local:backup/zbook";
  #     recursive = true;
  #   };
  # };
}
