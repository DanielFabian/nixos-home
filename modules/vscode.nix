{pkgs, ...}:

let hmConfig = {
  # ide: VS code
  programs.vscode = {
    enable = true;
    userSettings = {
      "editor.lineNumbers" = "relative";
      "keyboard.dispatch" = "keyCode";
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
