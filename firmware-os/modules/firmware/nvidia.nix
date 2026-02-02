# NVIDIA Quadro P1000 Mobile (Pascal) + Intel Optimus
{ config, pkgs, lib, ... }:

{
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # for Steam, Wine, etc
  };

  # NVIDIA driver - production branch for Pascal
  services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.nvidia = {
    # Use production driver (Pascal doesn't support nvidia-open)
    open = false;
    
    # Modesetting is required for Wayland
    modesetting.enable = true;
    
    # Power management - important for laptop
    powerManagement = {
      enable = true;
      finegrained = false;  # P1000 doesn't support RTD3
    };

    # PRIME offload for Optimus
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # provides `nvidia-offload` wrapper
      };
      
      # Bus IDs - from old config, verify with lspci
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";  # might need adjustment
    };

    # Disable dynamic boost (not supported, avoid warnings)
    dynamicBoost.enable = false;
  };

  # Environment for Wayland + NVIDIA
  environment.sessionVariables = {
    # Hint electron/chromium apps to use Wayland
    NIXOS_OZONE_WL = "1";
    
    # NVIDIA-specific Wayland tweaks
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    
    # Cursor fix for Hyprland + NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
