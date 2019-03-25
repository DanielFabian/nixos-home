# NixOS configuration 

1. `git clone` repository into `~/.config/nixpkgs`
1. `cd ~/.config/nixpkgs`
1. `ln -s` the appropriate `./systems/.../configuration.nix` to `/etc/nixos/configuration.nix`
1. rebuild the system `sudo nixos-rebuild switch` and be happy ;-).
   In case the system needs a separate `nixpkgs`, you can use `sudo nixos-rebuild -I nixpkgs=/path/to/nixpkgs switch`.
