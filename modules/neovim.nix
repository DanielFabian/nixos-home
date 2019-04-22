{pkgs, ...}:
let hmConfig = {

  programs.neovim = {
    enable = true;
    configure = {
      customRC = ''
        set relativenumber
        set ic
        let g:airline_theme='dark'
        let g:airline_powerline_fonts = 1
        '';
      packages.myVimPackages = with pkgs.vimPlugins; {
        start = [ vim-nix vim-airline vim-airline-themes ];
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
