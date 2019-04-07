{  
  imports = [
      "${builtins.fetchGit { url = https://github.com/rycee/home-manager; ref = "master"; }}/nixos"
  ];
  
  home-manager = {
    users = {
      root = import ../home.nix;
      dany = import ../home.nix;
    };
    useUserPackages = true;
  };
}