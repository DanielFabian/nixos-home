{pkgs, ...}:
let hmConfig = {
    home.packages = with pkgs; [
        # screen shots
        scrot
        screenfetch

        # titlebar for xmonad
        xmobar
    ];

    # control XSession from within home-manager:
    xsession = {
        enable = true;
        windowManager.xmonad = {
            enable = true;
            enableContribAndExtras = true;
            config = ./xmonad.hs;
        };
        pointerCursor = {
            package = pkgs.vanilla-dmz;
            name = "Vanilla-DMZ-AA";
            defaultCursor = "left_ptr";
            size = 16;
        };
        profileExtra = ''
        # bootstrap configuration, force loading.
        ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources
        
        # set background image.
        ${pkgs.feh}/bin/feh --bg-fill ~/.bg.png
        '';
    };

    home.file = {
        ".bg.png".source = ./bg.png;
        ".xinitrc".text = "exec ~/.xsession";
        ".xmobarrc".source = ./xmobarrc.hs;
    };

    # used for wallpaper: feh
    programs.feh.enable = true;

    # transparent windows: compton
    services.compton = {
        enable = true;
        blur = true;
        # fix sync issue with compton. This is probably an NVidia driver thing.
        # it looks like e.g. the terminal freezes, but it's just a re-draw problem.
        extraOptions = ''
        xrender-sync = true;
        xrender-sync-fence = true;
        '';
    };   
};
in
{  
  # Enable the X server.
    services.xserver = {
        displayManager.startx.enable = true;
        desktopManager = {
            default = "none";
            xterm.enable = false;
        };
    };

    home-manager.users = {
        dany = hmConfig;
        root = hmConfig;
    };
}