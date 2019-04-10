{pkgs, ...}:
let nmcfg = {
    home.file.".config/networkmanager-dmenu/config.ini".text = ''
        [dmenu]
        dmenu_command = rofi
        rofi_highlight = True
        '';
};
in
{
    environment.systemPackages = with pkgs; [
        networkmanagerapplet
        networkmanager_dmenu
    ];

    networking.networkmanager.enable = true;
    services.gnome3.gnome-keyring.enable = true;
 
    home-manager.users.dany = nmcfg;
    home-manager.users.root = nmcfg;
}
