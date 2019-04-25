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
  };
}
