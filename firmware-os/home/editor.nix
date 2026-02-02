# Editor configuration - LazyVim from unstable
{ config, pkgs, ... }:

{
  # Neovim from unstable for latest version
  programs.neovim = {
    enable = true;
    package = pkgs.unstable.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    # Don't manage plugins via Nix - let LazyVim handle it
    # This is the "let ecosystems be ecosystems" philosophy
  };

  # LazyVim expects these in PATH
  home.packages = with pkgs.unstable; [
    # Core dependencies
    gcc              # for treesitter compilation
    gnumake
    unzip
    curl
    
    # Language servers (LazyVim will prompt, but having them ready helps)
    lua-language-server
    nil              # nix LSP
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted  # html, css, json, eslint
    
    # Formatters
    stylua
    nixfmt
    prettierd
    
    # LazyVim extras
    lazygit
    ripgrep
    fd
  ];

  # LazyVim config lives in ~/.config/nvim
  # We bootstrap it, then it self-manages
  # TODO: Either clone lazyvim starter or use a custom config repo
  xdg.configFile."nvim/init.lua".text = ''
    -- Bootstrap lazy.nvim and LazyVim
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
      })
    end
    vim.opt.rtp:prepend(lazypath)

    require("lazy").setup({
      spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        -- Add your plugins here
      },
      defaults = { lazy = true, version = false },
      install = { colorscheme = { "tokyonight", "habamax" } },
      checker = { enabled = true },
      performance = {
        rtp = {
          disabled_plugins = {
            "gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin",
          },
        },
      },
    })
  '';
}
