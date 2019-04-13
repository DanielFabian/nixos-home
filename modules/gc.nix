{...}:
{
    nix.gc = {
        automatic = true;
        dates = "hourly";
        options = "--delete-older-than 30d";
    };
}