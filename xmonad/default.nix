{ lib, mkDerivation, X11, xmonad, xmonad-contrib, xmonad-extras, xmonad-log
, dbus, containers, utf8-string, polybar, makeWrapper, writeShellScript
, writeShellScriptBin, runCommandNoCCLocal, copyPathToStore, xorg, pavucontrol
, pulseaudio, mpv, xwinwrap, youtube-dl, feh, coreutils, gnugrep }:
let
  tray-start-script = writeShellScript "tray-start" ''
    ${polybar-alsa}/bin/polybar -c ${./polybar.ini} top &
    ${polybar-alsa}/bin/polybar -c ${./polybar.ini} bottom &
  '';
  tray-start =
    runCommandNoCCLocal "tray-start" { buildInputs = [ makeWrapper ]; } ''
      mkdir -p "$out/bin"
      makeWrapper "${tray-start-script}" "$out/bin/tray-start" \
        --prefix PATH : "${xmonad-log}/bin:${pavucontrol}/bin:${pulseaudio}/bin"
    '';
  polybar-alsa = polybar.override {
    pulseSupport = true;
    mpdSupport = true;
  };
  wallpaper-start = writeShellScriptBin "wallpaper-start" ''
    live_wallpaper="${"$"}{XDG_DATA_HOME-$HOME/.local/share}/wallpaper.webm"
    ${feh}/bin/feh --bg-fill ${wallpaper-still}
    if [ ! -f "$live_wallaper" ]; then
      ${youtube-dl}/bin/youtube-dl -f webm -o "$live_wallpaper" https://www.youtube.com/watch?v=m4P9XkF9gsI \
      || exit 1
    fi
    ${xwinwrap}/bin/xwinwrap \
      -ov \
      -g "$(${xorg.xrandr}/bin/xrandr -q | ${gnugrep}/bin/grep primary | ${coreutils}/bin/cut -f4 -d' ')" \
      -- ${mpv}/bin/mpv \
        -wid WID \
        --loop \
        --no-audio \
        --no-input-terminal \
        --no-input-cursor \
        --no-osd-bar \
        --cursor-autohide=no \
        --no-osc \
        --speed=0.75 \
        --quiet \
        --vf=hflip \
        "$live_wallpaper"
  '';
  wallpaper-still = builtins.fetchurl {
    url = "https://i.redd.it/2mcofpxwd2z61.jpg";
    sha256 = "0ag0abrmigi80xc4c86iv7fdf28nr6qf80k9aqha82gk115w035x";
  };
  unwrapped = mkDerivation {
    pname = "xmonad-config";
    version = "0.1.0.0";
    src = ./.;
    isLibrary = false;
    isExecutable = true;
    executableHaskellDepends =
      [ containers dbus utf8-string X11 xmonad xmonad-contrib xmonad-extras ];
    license = lib.licenses.gpl3;
  };
in runCommandNoCCLocal "xmonad-config" { buildInputs = [ makeWrapper ]; } ''
  mkdir -p "$out/bin"
  makeWrapper "${unwrapped}/bin/xmonad-config" "$out/bin/xmonad-config" \
    --prefix PATH : "${tray-start}/bin:${xorg.xsetroot}/bin:${pulseaudio}/bin:${wallpaper-start}/bin:${polybar}/bin"
'' // {
  inherit (unwrapped) env;
}
