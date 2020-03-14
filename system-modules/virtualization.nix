{pkgs, ...}:
{
    environment.systemPackages = with pkgs; [
        virtmanager
    ];

    virtualisation = {
      libvirtd.enable = true;
      virtualbox.host = {
        enable = true;
        enableExtensionPack = true;
      };
      lxd.enable = true;
    };
    boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };

    users.users.dany.extraGroups = [ "libvirtd" "vboxusers" "lxd" ];

    nixpkgs.config.packageOverrides = super: let self = super.pkgs; in {
      lxc = super.lxc.overrideAttrs (oldAttrs: rec {
        patches = oldAttrs.patches ++ [
          (self.fetchpatch {
          url = "https://github.com/lxc/lxc/commit/b31d62b847a3ee013613795094cce4acc12345ef.patch";
          sha256 = "1jpskr58ih56dakp3hg2yhxgvmn5qidi1vzxw0nak9afbx1yy9d4";
          }) 
        ];
      });
    };
}
