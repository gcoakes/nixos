inputs: final: prev:
with prev;
let
  settings = {
    "colors.webpage.darkmode.enabled" = "true";
    "bindings.commands.global.normal.\",m\"" = "spawn ${mpv}/bin/mpv {url}";
  };
in {
  qutebrowser = qutebrowser.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ makeWrapper ];
    postFixup = with lib;
      old.postFixup + ''
        wrapProgram $out/bin/qutebrowser \
          --argv0 qutebrowser \
          --add-flags ${
            escapeShellArg (concatStringsSep " " (map
              (k: "--set ${escapeShellArg k} ${escapeShellArg settings.${k}}")
              (attrNames settings)))
          }
      '';
  });
}
