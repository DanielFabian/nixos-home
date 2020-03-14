{...}:
let
  tempSnapshots = "1h=>30s,1d=>1h"; 
in
{  
  services.zfs.autoScrub.enable = true;
      
  # zfs snapshotting:
  services.znapzend = 
  {
    enable = true;
    pure = true;
    zetup = {
      "tank/nixos" = {
        plan = tempSnapshots;
        recursive = true;
      };
      "boot".plan = tempSnapshots;
    };
  };
}
