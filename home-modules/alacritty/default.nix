{pkgs, ...}:
{  
  # gpu accelerated terminal
  programs.alacritty = {
    enable = true;
    settings = {
      background_opacity = 0.7;
      live_config_reload = true;
      # Colors (Blood Moon)
      colors = {
        # Default colors
        primary = {
          background = "0x10100E";
          foreground = "0xC6C6C4";
        };

        # Normal colors
        normal = {
          black   = "0x10100E";
          red     = "0xC40233";
          green   = "0x009F6B";
          yellow  = "0xFFD700";
          blue    = "0x0087BD";
          magenta = "0x9A4EAE";
          cyan    = "0x20B2AA";
          white   = "0xC6C6C4";
        };

        # Bright colors
        bright = {
          black   = "0x696969";
          red     = "0xFF2400";
          green   = "0x03C03C";
          yellow  = "0xFDFF00";
          blue    = "0x007FFF";
          magenta = "0xFF1493";
          cyan    = "0x00CCCC";
          white   = "0xFFFAFA";
        };
      };
    };
  };
}
