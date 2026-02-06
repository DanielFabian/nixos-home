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
  };

  # IMPORTANT:
  # Don't export NVIDIA-specific GBM/GLX vars globally.
  # On hybrid laptops we want the compositor (Hyprland/niri) to run on Intel by default.
  # Forcing `GBM_BACKEND=nvidia-drm` and `__GLX_VENDOR_LIBRARY_NAME=nvidia` globally can
  # break Mesa/Intel EGL paths and lead to compositor startup/teardown crashes.
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "nvidia-offload-wayland" ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Start with NixOS-provided PRIME offload env.
      # (available because `hardware.nvidia.prime.offload.enableOffloadCmd = true`)
      if command -v nvidia-offload >/dev/null 2>&1; then
        exec nvidia-offload \
          env \
            GBM_BACKEND=nvidia-drm \
            __GLX_VENDOR_LIBRARY_NAME=nvidia \
            WLR_NO_HARDWARE_CURSORS=1 \
            "$@"
      fi

      exec env \
        __NV_PRIME_RENDER_OFFLOAD=1 \
        __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0 \
        __GLX_VENDOR_LIBRARY_NAME=nvidia \
        __VK_LAYER_NV_optimus=NVIDIA_only \
        GBM_BACKEND=nvidia-drm \
        WLR_NO_HARDWARE_CURSORS=1 \
        "$@"
    '')
  ];
}
