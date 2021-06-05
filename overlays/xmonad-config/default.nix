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
    ${feh}/bin/feh --bg-fill ${wallpaper-still}
    live_wallpaper="${"$"}{XDG_DATA_HOME-$HOME/.local/share}/wallpaper.webm"
    if [ -f "$live_wallaper" ]; then
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
          --quiet \
          --vf=hflip \
          "$live_wallpaper"
    fi
  '';
  video-wallpaper = writeShellScript "video-wallpaper" ''
    wid="$1"
    shift
    ${xorg.xprop}/bin/xprop -id "$wid" -f WM_CLASS 8s -set WM_CLASS Desktop
    ${xorg.xprop}/bin/xprop -id "$wid" -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY 0xffffffff
    exec ${mpv}/bin/mpv --wid="$wid" $@
  '';
  wallpaper-still = fetchurl {
    url = "https://i.imgur.com/hyt5lCu.jpg";
    hash = "sha256-3+VH9tO1iOWIGzE97j1SLu8dmVbxq32/qBwlUT82ONc=";
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
