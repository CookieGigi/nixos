{
  config,
  pkgs,
  ...
}: {
  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 4;
        margin-top = 6;
        margin-left = 6;
        margin-right = 6;

        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "tray"
          "cpu"
          "memory"
          "network"
          "pulseaudio"
          "battery"
        ];

        "niri/workspaces" = {
          format = "{name}";
        };

        "niri/window" = {
          max-length = 50;
          separate-outputs = true;
        };

        clock = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
        };

        cpu = {
          format = "CPU {usage}%";
          tooltip = true;
        };

        memory = {
          format = "RAM {}%";
        };

        network = {
          format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "{ipaddr}/{cidr}";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "Disconnected";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "Muted";
          format-icons = {
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-icons = ["" "" "" "" ""];
        };

        tray = {
          spacing = 10;
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", monospace;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: transparent;
        color: #cdd6f4;
      }

      window#waybar > box {
        background-color: #1e1e2e;
        border-radius: 12px;
        padding: 0 8px;
        margin: 0;
      }

      #workspaces button {
        padding: 0 10px;
        color: #cdd6f4;
        background-color: transparent;
        border: none;
        border-radius: 8px;
      }

      #workspaces button:hover {
        background-color: #313244;
      }

      #workspaces button.active {
        background-color: #45475a;
      }

      #workspaces button.urgent {
        background-color: #f38ba8;
        color: #1e1e2e;
      }

      #window {
        color: #a6adc8;
      }

      #clock,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #battery,
      #tray {
        padding: 0 10px;
        margin: 4px 0;
        border-radius: 8px;
        background-color: #313244;
      }

      #clock {
        background-color: #45475a;
        font-weight: bold;
      }

      #battery.critical {
        background-color: #f38ba8;
        color: #1e1e2e;
      }

      #battery.warning {
        background-color: #f9e2af;
        color: #1e1e2e;
      }

      #tray {
        background-color: transparent;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #f38ba8;
      }
    '';
  };
  programs.fuzzel.enable = true;
  services.mako.enable = true;
  programs.swaylock.enable = true;
  services.swayidle.enable = true;

  home.packages = with pkgs; [
    brightnessctl
    playerctl
    swaybg
    xwayland-satellite
    grim
    slurp
    libnotify

    (pkgs.writeShellScriptBin "screenshot-region" ''
      set -euo pipefail
      DIR="$HOME/Pictures/Screenshots"
      mkdir -p "$DIR"
      FILE="$DIR/Screenshot from $(date +%Y-%m-%d %H-%M-%S).png"
      grim -g "$(slurp)" "$FILE"
      echo -n "$FILE" | wl-copy
      notify-send "Screenshot copied" "Path saved to clipboard: $FILE"
    '')

    (pkgs.writeShellScriptBin "screenshot-full" ''
      set -euo pipefail
      DIR="$HOME/Pictures/Screenshots"
      mkdir -p "$DIR"
      FILE="$DIR/Screenshot from $(date +%Y-%m-%d %H-%M-%S).png"
      grim "$FILE"
      echo -n "$FILE" | wl-copy
      notify-send "Screenshot copied" "Path saved to clipboard: $FILE"
    '')
  ];
}
