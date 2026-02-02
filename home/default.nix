# Home Manager configuration for dany
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./shell.nix
    ./editor.nix
    ./terminal.nix
    ./keyboard.nix
    ./hyprland.nix
    ./apps.nix
  ];

  home.username = "dany";
  home.homeDirectory = "/home/dany";

  # Manage home-manager with home-manager
  programs.home-manager.enable = true;

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Git config
  programs.git = {
    enable = true;
    settings = {
      user.name = "Daniel Fabian";
      user.email = "daniel.fabian@integral-it.ch";  # update if changed
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # XDG directories
  xdg.enable = true;

  home.stateVersion = "25.11";
}
