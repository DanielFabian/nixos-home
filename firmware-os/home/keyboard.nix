# Keyboard configuration - Colemak-DH + caps/esc swap
{ config, pkgs, osConfig ? null, ... }:

{
  # Single source of truth: system-level XKB settings.
  # On NixOS, `console.useXkbConfig = true` can derive the TTY keymap from these.
  wayland.windowManager.hyprland.settings.input =
    let
      xkb = (osConfig.services.xserver.xkb or {});
      layout = xkb.layout or "us";
      variant = xkb.variant or "";
      model = xkb.model or "";
      options = xkb.options or "";
    in
    {
      kb_layout = layout;
      kb_variant = variant;
      kb_model = model;
      kb_options = options;
    
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
}
