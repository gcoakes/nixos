inputs: final: prev:
with prev;
let
  config = ''
    font_family FiraCode Nerd Font Mono
    enable_audio_bell no
    include ${inputs.kitty-themes}/themes/gruvbox_dark.conf
  '';
in {
  kitty = lib.wrapPrograms {
    name = "kitty";
    paths = [ kitty ];
    wrap.kitty = {
      file = "${kitty}/bin/kitty";
      flags =
        "--config ${lib.escapeShellArg (writeText "kitty-config" config)}";
    };
  };
}

