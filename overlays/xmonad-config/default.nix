{ lib, mkDerivation, containers, dbus, utf8-string, X11, xmonad, xmonad-contrib
, xmonad-extras, rofi, polybar, kitty, pulseaudio, xorg }:
mkDerivation {
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
      --subst-var-by polybar ${polybar} \
      --subst-var-by kitty ${kitty} \
      --subst-var-by pulseaudio ${pulseaudio} \
      --subst-var-by xsetroot ${xorg.xsetroot}
  '';
}
