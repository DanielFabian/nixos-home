{pkgs, config, ...}:
{
  # ide: VS code
  programs.vscode = {
    enable = true;
    userSettings = {
      "editor.lineNumbers" = "relative";
      "keyboard.dispatch" = "keyCode";
      "vim.enableNeovim" = true;
      "vim.neovimPath" = "${pkgs.neovim}/bin/nvim";
    };

    extensions =
      with pkgs.vscode-extensions;
      [
        # haskell
        justusadam.language-haskell
        # Nix
        bbenoist.Nix
        # vim key bindings
        vscodevim.vim
      ];
  };
}
