{  
  # get home-manager from github
  imports = [
      "${builtins.fetchGit { url = https://github.com/rycee/home-manager; ref = "master"; }}/nixos"
  ];
  
  # set up the same setup for both dany and root
  home-manager = {
    users = {
      root = import ../home.nix;
      dany = import ../home.nix;
    };
    useUserPackages = true;
  };
}