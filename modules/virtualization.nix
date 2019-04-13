{pkgs, ...}:
{
    environment.systemPackages = with pkgs; [
        virtmanager
    ];

    virtualisation.libvirtd.enable = true;
    boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };

    users.users.dany.extraGroups = [ "libvirtd" ];
}