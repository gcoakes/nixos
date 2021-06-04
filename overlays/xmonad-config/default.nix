{ lib, mkDerivation, containers, dbus, utf8-string, X11, xmonad, xmonad-contrib
, xmonad-extras, xmonad-log, polybar, makeWrapper, writeShellScript
, writeShellScriptBin, runCommandNoCCLocal, copyPathToStore, xorg, pavucontrol
, pulseaudio, mpv, xwinwrap, youtube-dl, feh, coreutils, gnugrep, fetchurl
, kitty, rofi }:
let
  trayStartScript = writeShellScript "trayStart" ''
    ${polybar-alsa}/bin/polybar -c ${./polybar.ini} top &
    ${polybar-alsa}/bin/polybar -c ${./polybar.ini} bottom &
  '';
  trayStart =
    runCommandNoCCLocal "trayStart" { buildInputs = [ makeWrapper ]; } ''
      mkdir -p "$out/bin"
      makeWrapper "${trayStartScript}" "$out/bin/trayStart" \
        --prefix PATH : "${xmonad-log}/bin:${pavucontrol}/bin:${pulseaudio}/bin"
    '';
  polybar-alsa = polybar.override {
    pulseSupport = true;
    mpdSupport = true;
  };
  wallpaperStart = writeShellScriptBin "wallpaperStart" ''
    live_wallpaper="${"$"}{XDG_DATA_HOME-$HOME/.local/share}/wallpaper.webm"
    ${feh}/bin/feh --bg-fill ${wallpaper-still}
    if [ ! -f "$live_wallaper" ]; then
      ${youtube-dl}/bin/youtube-dl -f webm -o "$live_wallpaper" https://www.youtube.com/watch?v=m4P9XkF9gsI \
      || exit 1
    fi
    ${xwinwrap}/bin/xwinwrap \
      -ov \
      -g "$(${xorg.xrandr}/bin/xrandr -q | ${gnugrep}/bin/grep primary | ${coreutils}/bin/cut -f4 -d' ')" \
      -- ${video-wallpaper} WID \
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
  video-wallpaper = writeShellScript "video-wallpaper" ''
    wid="$1"
    shift
    ${xorg.xprop}/bin/xprop -id "$wid" -f WM_CLASS 8s -set WM_CLASS Desktop
    ${xorg.xprop}/bin/xprop -id "$wid" -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY 0xffffffff
    exec ${mpv}/bin/mpv --wid="$wid" $@
  '';
  wallpaper-still = fetchurl {
    url = "https://i.redd.it/2mcofpxwd2z61.jpg";
    sha256 = "0ag0abrmigi80xc4c86iv7fdf28nr6qf80k9aqha82gk115w035x";
  };
in mkDerivation {
  pname = "xmonad-config";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends =
    [ containers dbus utf8-string X11 xmonad xmonad-contrib xmonad-extras ];
  license = lib.licenses.gpl3;
  patchPhase = ''
    substituteInPlace Main.hs \
      --subst-var-by rofi ${rofi} \
      --subst-var-by polybar ${polybar-alsa} \
      --subst-var-by kitty ${kitty} \
      --subst-var-by wallpaperStart ${wallpaperStart} \
      --subst-var-by pulseaudio ${pulseaudio} \
      --subst-var-by xsetroot ${xorg.xsetroot} \
      --subst-var-by trayStart ${trayStart}
    cat Main.hs
  '';
}
