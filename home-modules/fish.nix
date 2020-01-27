{pkgs, ...}:
{  
  # supposedly cool shell: fish
  programs.fish = {
    enable = true;
    shellInit = ''
      fish_vi_key_bindings
      fish_vi_cursor
      '';
  };

  xdg.dataFile."fish/generated_completions/az.fish".source = 
      pkgs.runCommand "az.fish" {} "${pkgs.python38Packages.argcomplete}/bin/register-python-argcomplete --shell fish az > $out";
}
