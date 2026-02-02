# Zsh configuration
{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    # Vi mode
    defaultKeymap = "viins";
    
    initExtra = ''
      # Vi mode indicator in prompt
      function zle-line-init zle-keymap-select {
        case $KEYMAP in
          vicmd) echo -ne '\e[2 q';;  # block cursor
          viins|main) echo -ne '\e[6 q';;  # beam cursor
        esac
      }
      zle -N zle-line-init
      zle -N zle-keymap-select

      # Fast escape key
      KEYTIMEOUT=1
    '';

    shellAliases = {
      # Nix shortcuts
      rebuild = "sudo nixos-rebuild switch --flake ~/src/firmware-os#zbook";
      update = "nix flake update ~/src/firmware-os && rebuild";
      
      # Common
      ls = "eza";
      ll = "eza -la";
      cat = "bat";
      
      # Git
      g = "git";
      gs = "git status";
      gd = "git diff";
      gc = "git commit";
      gp = "git push";
    };
  };

  # Starship prompt - fast, minimal
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$character";
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        vicmd_symbol = "[❮](blue)";
      };
    };
  };

  # Modern CLI tools
  programs.eza.enable = true;         # ls replacement
  programs.bat.enable = true;         # cat replacement
  programs.fd.enable = true;          # find replacement
  programs.ripgrep.enable = true;     # grep replacement
  programs.fzf.enable = true;         # fuzzy finder
  programs.zoxide.enable = true;      # cd replacement

  # Direnv for auto-loading devcontainer envs
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
