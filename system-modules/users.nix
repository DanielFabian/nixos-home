{pkgs, ...}:
{  
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users = {
        dany = {
            isNormalUser = true;
            description = "Daniel Fabian";
            home = "/home/dany";
            shell = pkgs.fish;
            # Enable ‘sudo’ for the user.
            extraGroups = [ "wheel" "video" "audio" "plugdev" ];
        };

        root = {
            shell = pkgs.fish;
        };
    };

    programs.fish.enable = true;
    # No password for sudo
    security.sudo.wheelNeedsPassword = false;
}
