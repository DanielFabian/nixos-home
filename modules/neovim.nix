{pkgs, ...}:
let hmConfig = {

  programs.neovim = {
    enable = true;
    configure = {
      customRC = ''
        set relativenumber
        set ic
        '';
      packages.myVimPackages = with pkgs.vimPlugins; {
        start = [ vim-nix ];
      };
    };
    viAlias = true;
    vimAlias = true;
  };
};
in 
{
    home-manager.users = {
        dany = hmConfig;
        root = hmConfig;
    };
}
