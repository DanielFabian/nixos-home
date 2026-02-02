{
  description = "Firmware OS - GNU/Linux except Linux";

  inputs = {
    # Firmware layer - stable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    
    # Apps layer - unstable
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home manager - match stable
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland - track their flake for freshness
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, disko, lanzaboote, hyprland, ... }@inputs:
  let
    # Unstable overlay for rolling apps
    unstableOverlay = final: prev: {
      unstable = nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
    };
  in
  {
    nixosConfigurations = {
      zbook = nixpkgs.lib.nixosSystem {
        # system inferred from hardware-configuration.nix (nixpkgs.hostPlatform)
        specialArgs = { inherit inputs; };
        modules = [
          # Declarative disk layout
          disko.nixosModules.disko
          ./disko/zbook.nix

          # Secure boot
          lanzaboote.nixosModules.lanzaboote

          # Home manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.dany = import ./home;
          }

          # Overlays + unfree (NVIDIA driver)
          { 
            nixpkgs.overlays = [ unstableOverlay ];
            nixpkgs.config.allowUnfree = true;
          }

          # Machine config
          ./hosts/zbook
        ];
      };
    };
  };
}
