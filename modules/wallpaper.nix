{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.xserver.wallpaper;
  staticService = {
    script = ''
      feh --bg-fill ${escapeShellArg cfg.image}
    '';
    serviceConfig.Type = "oneshot";
    path = [ pkgs.feh ];
  };
  liveService = {
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

      ${if cfg.image != null then
        "feh --bg-fill ${escapeShellArg cfg.image}"
      else
        ""}
      live_wallpaper="${
        if cfg.live.cache == null then
          "\${XDG_DATA_HOME-$HOME/.local/share}/wallpapers/''${
            builtins.hashString "sha256" cfg.live.url
          }.${cfg.live.format}"
        else
          cfg.live.cache
      }"
      if [ ! -f "$live_wallaper" ]; then
        youtube-dl --format ${cfg.live.format} --output "$live_wallpaper" ${
          escapeShellArg cfg.live.url
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
          ${concatStringsSep " " (map escapeShellArg cfg.live.extraMpvArgs)} \
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
  };
in {
  options.services.xserver.wallpaper = {
    enable = mkEnableOption "xserver wallpaper";

    image = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        A file or directory which should be used by feh as the root
        wallpaper.
      '';
    };

    live = {
      enable = mkEnableOption "live wallpaper";

      url = mkOption {
        type = types.str;
        description = ''
          A URL which is able to be downloaded via youtube-dl.
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
          ''${XDG_DATA_HOME-$HOME/.local/share}/''${builtins.hashString "sha256" services.wallpaper.url}.''${services.wallpaper.format}'';
        description = ''
          A shell string which is used to determine the location to store the
          cache file.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.wallpaper = {
      enable = true;
      description = "Wallpaper";
      wantedBy = [ "graphical-session.target" ];
    } // (if cfg.live.enable then liveService else staticService);
  };
}
