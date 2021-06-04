{ pkgs, lib, config, ... }:
let cfg = config.programs.direnv;
in {
  options = {
    programs.direnv = {
      enable = lib.mkEnableOption "direnv, the environment switcher";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.direnv;
      };
      enableZshIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    programs.zsh.shellInit = lib.mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/direnv hook zsh)"
    '';
  };
}
