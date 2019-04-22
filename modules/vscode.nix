{pkgs, config, ...}:
let hmConfig = {
  # ide: VS code
  programs.vscode = {
    enable = true;
    userSettings = {
      "editor.lineNumbers" = "relative";
      "keyboard.dispatch" = "keyCode";
      "vim.enableNeovim" = true;
      "vim.neovimPath" = "${pkgs.neovim}/bin/nvim";
      "editor.fontFamily" =
        builtins.concatStringsSep ", " 
        (map (x: "'${x}'") config.fonts.fontconfig.defaultFonts.monospace);
      "editor.fontSize" = 16;
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
};
in
{
    home-manager.users = {
        dany = hmConfig;
        root = hmConfig;
    };
}
