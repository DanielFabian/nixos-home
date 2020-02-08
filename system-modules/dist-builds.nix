{...}:
{
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "dany-pc";
        maxJobs = 8;
        sshKey = "/home/dany/.ssh/id_rsa";
        sshUser = "dany";
        system = "x86_64-linux";
      }
    ];
    binaryCaches = [ "ssh-ng://dany-pc" ];
    binaryCachePublicKeys = [
      "dany-pc:p002xhY4CfoAkj/uWW4xgvBRXv61UTxyKM/Cwv6OloA="
    ];
    trustedUsers = [ "root" "@wheel" ];
  };
}
