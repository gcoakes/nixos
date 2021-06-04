{ config, lib, pkgs, ... }:
let cfg = config.programs.lesspipe;
in {
  options = {
    programs.lesspipe = {
      enable = lib.mkEnableOption "lesspipe preprocessor for less";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.lesspipe;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.variables = {
      LESSOPEN = "|${cfg.package}/bin/lesspipe.sh %s";
    };
  };
}
