{pkgs, ...}:
{
    environment.systemPackages = with pkgs; [
        virtmanager
    ];

    virtualisation.libvirtd.enable = true;
    virtualisation.virtualbox.host.enable = true;
    virtualisation.virtualbox.host.enableExtensionPack = true;
    boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };

    users.users.dany.extraGroups = [ "libvirtd" "vboxusers" ];
}
