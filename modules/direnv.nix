{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.programs.direnv;
  wrapPrograms = pkgs.callPackage ../overlays/lib/wrap-programs.nix { };
  wrapped = wrapPrograms {
    inherit (cfg) package;
    wrap.direnv.run = ''
      if [ ! -f .envrc ] && [ -f shell.nix ]; then
        echo use nix >> .envrc
      fi
    '';
  };
in {
  options = {
    programs.direnv = {
      enable = mkEnableOption "direnv, the environment switcher";

      package = mkOption {
        type = types.package;
        default = pkgs.direnv;
      };

      enableZshIntegration = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ wrapped pkgs.nix-direnv ];
    environment.pathsToLink = [ "/share/nix-direnv" ];
    programs.zsh.shellInit = mkIf cfg.enableZshIntegration ''
      eval "$(${wrapped}/bin/direnv hook zsh)"
    '';
  };
}
