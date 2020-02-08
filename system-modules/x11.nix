{...}:
{
  # Enable the X server.
  services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
      desktopManager = {
          xterm.enable = false;
      };
  };
}
