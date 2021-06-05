{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.live-wallpaper;
in {
  options.services.live-wallpaper = {
    enable = mkEnableOption "live wallpaper";

    url = mkOption {
      type = types.str;
      description = ''
        A URL which is able to be downloaded via youtube-dl.
      '';
    };

    fallback = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        A file or directory which should be used by feh as a fallback in
        the event the url cannot be downloaded.
      '';
    };

    format = mkOption {
      type = types.str;
      default = "webm";
      description = ''
        The format of the video which should be downloaded.
      '';
    };

    extraMpvArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Additional arguments which will be given to mpv.
      '';
    };

    cache = mkOption {
      type = types.nullOr types.str;
      default = null;
      defaultText = literalExample ''
        ''${XDG_DATA_HOME-$HOME/.local/share}/''${builtins.hashString "sha256" services.live-wallpaper.url}.''${services.live-wallpaper.format}'';
      description = ''
        A shell string which is used to determine the location to store the
        cache file.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.live-wallpaper = {
      enable = true;
      description = "Live wallpaper";
      restartTriggers = [ cfg.fallback cfg.url ];
      script = let
        video-wallpaper = pkgs.writeShellScript "video-wallpaper" ''
          wid="$1"
          shift
          xprop -id "$wid" -f WM_CLASS 8s -set WM_CLASS Desktop
          xprop -id "$wid" -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY 0xffffffff
          exec mpv --wid="$wid" $@
        '';
      in ''
        set -e

        ${if cfg.fallback != null then "feh --bg-fill ${cfg.fallback}" else ""}
        live_wallpaper="${
          if cfg.cache == null then
            "\${XDG_DATA_HOME-$HOME/.local/share}/wallpapers/''${
              builtins.hashString "sha256" cfg.url
            }.${cfg.format}"
          else
            cfg.cache
        }"
        if [ ! -f "$live_wallaper" ]; then
          youtube-dl --format ${cfg.format} --output "$live_wallpaper" ${
            escapeShellArg cfg.url
          }
        fi
        xwinwrap \
        -ov \
        -g "$(xrandr -q | grep primary | cut -f4 -d' ')" \
        -- ${video-wallpaper} WID \
            --loop \
            --no-audio \
            --no-input-terminal \
            --no-input-cursor \
            --no-osd-bar \
            --cursor-autohide=no \
            --no-osc \
            --quiet \
            ${concatStringsSep " " (map escapeShellArg cfg.extraMpvArgs)} \
            "$live_wallpaper"
      '';
      path = with pkgs; [
        coreutils
        feh
        gnugrep
        mpv
        xorg.xprop
        xorg.xrandr
        xwinwrap
        youtube-dl
      ];
      wantedBy = [ "graphical-session.target" ];
    };
  };
}
