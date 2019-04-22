{...}:
{
  nix = {
    distributedBuilds = true;
    buildMachines = [
      hostName = "dany-pc";
      maxJobs = 8;
      sshKey = "/dany/.ssh/id_rsa";
      sshUser = "dany";
      system = "x86_64-linux";
    ];
  };
}
