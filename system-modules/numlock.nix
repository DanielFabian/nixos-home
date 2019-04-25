{pkgs, ...}:
{  
  systemd.user.services.numlockx = {
    description = "Set numlock to on during X11 session";
    after = [ "graphical-session-pre.target" ];
    partOf = [ "graphical-session.target" ];
    script = "${pkgs.numlockx}/bin/numlockx";
    serviceConfig.Type = "oneshot";
    wantedBy = [ "graphical-session.target" ];
  };

    # numlock on boot in console mode
  systemd.services."getty@" = {
    description = "Keep numlock on in console mode";
    serviceConfig = {
      ExecStartPre="/bin/sh -c '${pkgs.kbd}/bin/setleds -D +num < /dev/%I'";
    };
  };
}