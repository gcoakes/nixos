{ lib, mkDerivation, xmonad, xmonad-contrib, xmonad-extras, dbus, containers, utf8-string }:
mkDerivation {
  pname = "xmonad-config";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    xmonad
    xmonad-contrib
    xmonad-extras
    dbus
    containers
    utf8-string
  ];
  license = lib.licenses.gpl3;
}
