{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.programs.git;
  wrapPrograms = pkgs.callPackage ../overlays/lib/wrap-programs.nix { };
  userOpts = { name, config, ... }: {
    options = {
      config = mkOption {
        type = types.attrs;
        default = { };
      };
    };
  };
  wrapGit = gitConfig:
    wrapPrograms {
      inherit (cfg) package;
      wrap.git = {
        set = with builtins;
          {
            GIT_CONFIG_COUNT = toString (length (attrNames gitConfig));
          } // foldl' (acc: x:
            let n = toString (length (attrNames acc) / 2);
            in acc // {
              "GIT_CONFIG_KEY_${n}" = x.name;
              "GIT_CONFIG_VALUE_${n}" = toString x.value;
            }) { } (mapAttrsToList nameValuePair gitConfig);
        inherit (cfg) extraPackages;
      };
    };
in {
  options = {
    programs.git = {
      enable = mkEnableOption "Git";
      package = mkOption {
        type = types.package;
        default = pkgs.git;
      };
      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
      config = mkOption {
        type = types.attrs;
        default = { };
      };
      users = mkOption {
        type = with types; attrsOf (submodule userOpts);
        default = { };
      };
    };
  };
  config = mkIf cfg.enable {
    users.users = mapAttrs
      (user: opts: { packages = [ (wrapGit (cfg.config // opts.config)) ]; })
      cfg.users;
    environment.systemPackages = [ (wrapGit cfg.config) ];
  };
}
