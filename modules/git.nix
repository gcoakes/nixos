{ pkgs, lib, config, ... }:
let
  cfg = config.programs.git;
  wrapPrograms = pkgs.callPackage ../overlays/lib/wrap-programs.nix { };
  userOpts = { name, config, ... }: {
    options = {
      config = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
    };
  };
  wrapGit = git: gitConfig:
    wrapPrograms {
      package = git;
      wrap.git.set = with builtins;
        {
          GIT_CONFIG_COUNT = toString (length (attrNames gitConfig));
        } // foldl' (acc: x:
          let n = toString (length (attrNames acc) / 2);
          in acc // {
            "GIT_CONFIG_KEY_${n}" = x.name;
            "GIT_CONFIG_VALUE_${n}" = toString x.value;
          }) { } (lib.mapAttrsToList lib.nameValuePair gitConfig);
    };
in {
  options = {
    programs.git = {
      enable = lib.mkEnableOption "Git";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.git;
      };
      config = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
      users = lib.mkOption {
        type = with lib.types; attrsOf (submodule userOpts);
        default = { };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    users.users = lib.mapAttrs (user: opts: {
      packages = [ (wrapGit cfg.package (cfg.config // opts.config)) ];
    }) cfg.users;
    environment.systemPackages = [ (wrapGit cfg.package cfg.config) ];
  };
}
