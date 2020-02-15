{pkgs, ...}:
{
  programs.neovim = {
    enable = true;
    configure = {
      customRC = ''
        set relativenumber
        set ic
        let g:airline_theme='dark'
        if $TERM !~ 'linux'
          let g:airline_powerline_fonts = 1
        endif
        set autoindent
        set shiftwidth=2
        set softtabstop=2
        set expandtab
        '';
      packages.myVimPackages = with pkgs.vimPlugins; {
        start = [ vim-nix vim-airline vim-airline-themes vim-easymotion ];
      };
    };
    viAlias = true;
    vimAlias = true;
  };
}
