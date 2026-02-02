# Keyboard configuration - Colemak-DH + caps/esc swap
{ config, pkgs, ... }:

{
  # Steal from old config: caps-to-escape swap
  # In Wayland/Hyprland, this is done via XKB options
  
  wayland.windowManager.hyprland.settings.input = {
    kb_layout = "us";
    kb_variant = "colemak_dh";  # Colemak-DH variant
    kb_options = "caps:escape";  # Caps Lock → Escape (vim life)
    
    # Touchpad settings (laptop)
    touchpad = {
      natural_scroll = true;
      tap-to-click = true;
      disable_while_typing = true;
    };
    
    # Sensible defaults
    follow_mouse = 1;
    sensitivity = 0;  # no acceleration
  };

  # For apps that need explicit XKB config (rare)
  home.sessionVariables = {
    XKB_DEFAULT_LAYOUT = "us";
    XKB_DEFAULT_VARIANT = "colemak_dh";
    XKB_DEFAULT_OPTIONS = "caps:escape";
  };
}
