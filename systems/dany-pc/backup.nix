{pkgs, ...}:

let config = ''
  sync {
    default.rsync,
    source = "/home/",
    target = "/mnt/data/home/",
    delay = 15,
    rsync = {
      binary = "${pkgs.rsync}/bin/rsync",
      archive = true,
    }
  }'';

  configFile = pkgs.writeText "lsyncd.conf.lua" config;
in
{  
  # needed for zfs
  networking.hostId = "6d7416e5";
  services.zfs.autoScrub.enable = true;
  
  # zfs snapshotting:
  services.znapzend = {
    enable = true;
    zetup = {
      "data/root" = {
        plan = "1h=>30s,7d=>1h,30d=>4h,90d=>1d,1y=>1w,10y=>1m";
      };

      "data/home" = {
        plan = "1h=>30s,7d=>1h,30d=>4h,90d=>1d";
        destinations.local = {
          dataset = "backup/home";
          plan = "1h=>30s,7d=>1h,30d=>4h,90d=>1d,1y=>1w,10y=>1m";
        };
      };
    };
  };

  # sync home directory 
  systemd.services.lsyncd = {
    description = "Live Syncing (Mirror) Daemon";
    after = [ "network.target" ];
    serviceConfig = {
      Restart = "always";
      Type = "simple";
      Nice = 19;
      ExecStart="${pkgs.lsyncd}/bin/lsyncd -nodaemon -pidfile /run/lsyncd.pid ${configFile}";
      ExecReload="${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      PIDFile="/run/lsyncd.pid";
    };
    wantedBy = [ "multi-user.target" ];
  };
}