{ makeWrapper, writeShellScript, symlinkJoin, runCommandNoCCLocal, lib }:
let
  wrapExecutable =
    { name, file ? null, script ? null, path ? [ ], env ? { }, flags ? "" }:
    assert file != null || script != null
      || abort "wrap needs 'file' or 'script' argument";
    let
      pathPrefix = lib.escapeShellArg
        (builtins.concatStringsSep ":" (map (p: "${p}/bin") path));
      envArgs = with lib;
        builtins.concatStringsSep " " (attrsets.mapAttrsToList
          (k: v: "--set ${escapeShellArg k} ${escapeShellArg v}") env);
    in runCommandNoCCLocal name {
      inherit name;
      f = if file == null then writeShellScript name script else file;
      buildInputs = [ makeWrapper ];
    } ''
      makeWrapper "$f" "$out" --prefix PATH : ${pathPrefix} ${envArgs} ${
        if flags != "" then "--add-flags ${lib.escapeShellArg flags}" else ""
      }
    '';
in { name ? null, paths ? [ ], wrap ? { } }:
symlinkJoin {
  name = if name == null then (builtins.head paths).name else name;
  inherit paths;
  preferLocalBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  postBuild = let
    replaceExecutable = name: args:
      let realArgs = { inherit name; } // args;
      in ''
        rm "$out/bin/${realArgs.name}"
        ln -s "${wrapExecutable realArgs}" "$out/bin/${realArgs.name}"
      '';
  in builtins.concatStringsSep "\n"
  (lib.attrsets.mapAttrsToList replaceExecutable wrap);
}
