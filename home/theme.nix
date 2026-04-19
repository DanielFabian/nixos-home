# Visual appearance - GTK, Qt, cursors, icons
# This gives apps a consistent dark theme
{ config, pkgs, ... }:

{
  # GTK theme
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };

    font = {
      name = "Cantarell";
      size = 11;
    };
  };

  # Tell GTK apps to prefer dark mode via dconf
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # Qt follows GTK
  qt = {
    enable = true;
    # Wayland-safe: avoid the legacy gtk2 platform theme plugin, which
    # expects an X11 DISPLAY and can break under compositors without Xwayland.
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };
}
