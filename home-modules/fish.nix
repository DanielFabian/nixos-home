{pkgs, ...}:
{  
  # supposedly cool shell: fish
  programs.fish = {
    enable = true;
    loginShellInit = ''
      fish_vi_key_bindings
      fish_vi_cursor
      '';
  };
}
