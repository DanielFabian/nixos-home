# User account - Daniel
{ config, pkgs, ... }:

{
  users.users.dany = {
    isNormalUser = true;
    description = "Daniel Fabian";
    home = "/home/dany";
    shell = pkgs.zsh;
    extraGroups = [ 
      "wheel"           # sudo
      "video"           # GPU access
      "audio"           # sound
      "networkmanager"  # wifi control
      "docker"          # container management
      "libvirtd"        # VM management
      "plugdev"         # USB devices
    ];
    
    # SSH keys (add your public key)
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... dany@somewhere"
    ];
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Passwordless sudo for wheel
  security.sudo.wheelNeedsPassword = false;

  # Home-manager manages the actual user config
}
