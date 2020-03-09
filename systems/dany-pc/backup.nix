{...}:
let
  tempSnapshots = "1h=>30s,1d=>1h"; 
  longTermSnapshots = tempSnapshots + "," + "30d=>4h,90d=>1d,1y=>1w,10y=>1m"; 
  backup = dataset: {
      plan = tempSnapshots;
      destinations.local = {
        dataset = "backup/${dataset}";
        plan = longTermSnapshots;
      };
    }; in
{  
  services.zfs.autoScrub.enable = true;
  
      
  # zfs snapshotting:
  services.znapzend = 
  {
    enable = true;
    zetup = {
      "system/nixos" = backup "system/nixos";
      "data" = backup "data";
    };
  };
}
