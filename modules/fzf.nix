{ pkgs, lib, config, ... }:
let cfg = config.programs.fzf;
in {
  options = {
    programs.fzf = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.fzf;
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
      if [[ $options[zle] = on ]]; then
        . ${cfg.package}/share/fzf/completion.zsh
        . ${cfg.package}/share/fzf/key-bindings.zsh
      fi
    '';
  };
}
