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
    package = kitty;
    wrap.kitty.addFlags = [ "--config" "${writeText "kitty-config" config}" ];
  };
}

