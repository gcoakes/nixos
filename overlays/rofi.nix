inputs: final: prev:
with prev;
let
  rofi-simple-pass = writeShellScript "rofi-simple-pass" ''
    if [ "$#" -gt 0 ]; then
      pass -c $@ 1>/dev/null 2>&1
    else
      store="$HOME/.password-store"
      ${findutils}/bin/find "$store" -name '*.gpg' \
      | ${gnused}/bin/sed "s|^$store/\(.*\)\.gpg$|\1|"
    fi
  '';
  config = prev.writeTextFile {
    name = "rofi-config.rasi";
    text = ''
      configuration {
        modi: "drun,run,file-browser,pass:${rofi-simple-pass}";
        theme: "gruvbox-dark";
        show-icons: true;
        sidebar-mode: true;
        terminal: "kitty";
      }
    '';
  };
in {
  rofi = lib.wrapPrograms {
    package = rofi;
    wrap.rofi.addFlags = [ "-config" "${config}" ];
  };
}
