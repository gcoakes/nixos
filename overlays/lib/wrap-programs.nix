{ lib, makeWrapper, writeShellScript, symlinkJoin }:
with lib;
let
  replaceExecutable = with lib;
    name:
    { # The path within the derivation which should be replaced.
    path ? "/bin/${name}"
    , # Derivations which should be prefixed to the executable's PATH.
    extraPackages ? [ ]
    , # Environment variables which should be set for the executable.
    set ? { }
    , # Environment variables which should be set if not already for the executable.
    setDefault ? { }
    , # Environment variables which should be removed from the exectuables.
    unset ? [ ]
    , # A derivation or script which should be run synchronously prior to the executable.
    run ? null, # Additional flags to the executable.
    addFlags ? [ ] }:
    let
      runArgs = if run != null then [
        "--run"
        (if isDerivation run then
          "${run}/bin/${run.pname}"
        else
          (writeShellScript "${name}-before-script" run))
      ] else
        [ ];
      pathPrefix = concatStringsSep ":" [
        (makeBinPath extraPackages)
        (makeSearchPathOutput "bin" "sbin" extraPackages)
      ];
      prefixArgs = [ "--prefix" "PATH" ":" pathPrefix ];
      makeSetArgs = arg: attrs:
        concatLists (mapAttrsToList (k: v: [ arg k v ]) attrs);
      setArgs = makeSetArgs "--set" set;
      setDefaultArgs = makeSetArgs "--set-default" setDefault;
      unsetArgs = concatMap (x: [ "--unset" x ]) unset;
      addFlagsArgs = [ "--add-flags" (escapeShellArgs addFlags) ];
      wrapArgs = runArgs ++ prefixArgs ++ setArgs ++ setDefaultArgs ++ unsetArgs
        ++ addFlagsArgs;
    in ''wrapProgram "$out${path}" ${escapeShellArgs wrapArgs}'';
in { package, wrap ? { } }:
symlinkJoin {
  inherit (package) name;
  paths = [ package ];
  preferLocalBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  postBuild = concatStringsSep "\n" (mapAttrsToList replaceExecutable wrap);
}
