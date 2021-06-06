inputs: final: prev:
with prev;
let
  config = writeText "config.py" ''
    c.colors.webpage.darkmode.enabled = True;
    config.bind(",m", "spawn ${mpv}/bin/mpv {url}")
  '';
in {
  qutebrowser = qutebrowser.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ makeWrapper ];
    postFixup = with lib;
      old.postFixup + ''
        wrapProgram $out/bin/qutebrowser \
          --argv0 qutebrowser \
          --add-flags ${escapeShellArg "-C ${escapeShellArg config}"}
      '';
  });
}
