{pkgs, ...}:

{  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    dany = {
        isNormalUser = true;
        description = "Daniel Fabian";
        home = "/home/dany";
        shell = pkgs.fish;
        extraGroups = [ "wheel" "libvirtd" ]; # Enable ‘sudo’ for the user.
    };

    root = {
        shell = pkgs.fish;
    };
  };
}