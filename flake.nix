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

    # Declarative flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # DankMaterialShell - Quickshell-based desktop shell
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs-unstable"; # DMS needs unstable
    };

    # dgop for DMS system monitoring (not in stable nixpkgs)
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Hyprland - track their flake for freshness
    hyprland.url = "github:hyprwm/Hyprland";

    # VM image generation (Hyper-V VHDX for devhost)
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      disko,
      lanzaboote,
      nix-flatpak,
      dms,
      dgop,
      hyprland,
      nixos-generators,
      ...
    }@inputs:
    let
      # Unstable overlay for rolling apps (with unfree enabled)
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations = {
        zbook = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./disko/zbook.nix
            lanzaboote.nixosModules.lanzaboote
            nix-flatpak.nixosModules.nix-flatpak
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.dany = import ./home;
            }
            {
              nixpkgs.overlays = [ unstableOverlay ];
              nixpkgs.config.allowUnfree = true;
            }
            ./hosts/zbook
          ];
        };

        x1carbon = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./disko/x1carbon.nix
            lanzaboote.nixosModules.lanzaboote
            nix-flatpak.nixosModules.nix-flatpak
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.dany = import ./home;
            }
            {
              nixpkgs.overlays = [ unstableOverlay ];
              nixpkgs.config.allowUnfree = true;
            }
            ./hosts/x1carbon
          ];
        };

        # Sovereign-codespaces devhost variants. Deliberately minimal:
        # no desktop, no home-manager, no flatpak. Just sshd + docker + nix.
        # x86_64 / Hyper-V variant — runs on Windows hypervisor at home.
        devhost-hyperv = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/devhost-hyperv ];
        };

        # aarch64 / Apple Virtualization variant — runs on Apple Silicon
        # Macs as a local sovereign codespace. Same cattle invariants, just
        # different substrate.
        devhost-mac = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/devhost-mac ];
        };
      };

      # ── devhost-hyperv build outputs ──────────────────────────────────
      # `nix build .#devhost-hyperv-image` produces a Hyper-V VHDX ready to
      # import. Requires a builder with /dev/kvm (the hyperv format runs a
      # real VM to assemble the disk). Build on x1carbon/zbook, not in
      # WSL/container.
      packages.x86_64-linux.devhost-hyperv-image = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "hyperv";
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/devhost-hyperv ];
      };

      # `nix build .#devhost-hyperv-iso` produces a bootable installer ISO.
      # No KVM required — builds fine in WSL/containers. Workflow:
      #   New-VM -Generation 2 -Name devhost -MemoryStartupBytes 8GB
      #   Set-VMFirmware -VMName devhost -EnableSecureBoot Off
      #   New-VHD -Path os.vhdx       -Dynamic -SizeBytes 64GB
      #   New-VHD -Path workspace.vhdx -Dynamic -SizeBytes 200GB
      #   Add-VMHardDiskDrive -VMName devhost -Path os.vhdx
      #   Add-VMHardDiskDrive -VMName devhost -Path workspace.vhdx
      #   Add-VMDvdDrive      -VMName devhost -Path devhost.iso
      #   Start-VM devhost
      # The ISO auto-partitions /dev/sda with GPT+ESP+ext4, runs
      # `nixos-install --flake github:DanielFabian/nixos-home#devhost-hyperv`,
      # reboots. First boot then formats /dev/sdb as label=workspace and
      # prints dany's freshly generated SSH pubkey to the MOTD.
      packages.x86_64-linux.devhost-hyperv-iso = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "install-iso";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/devhost-hyperv/installer.nix
        ];
      };

      # ── devhost-mac build outputs ─────────────────────────────────────
      # aarch64 ISO. install-iso format needs no KVM, so any aarch64 host
      # with /nix can build this — including the M5 Mac itself once it
      # arrives (`nix build github:DanielFabian/nixos-home#devhost-mac-iso`).
      packages.aarch64-linux.devhost-mac-iso = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        format = "install-iso";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/devhost-mac/installer.nix
        ];
      };
    };
}
