{ config, lib, pkgs, ... }:
with lib;
let

  cfg = config.programs.lsd;

  aliases = {
    ls = "${cfg.package}/bin/lsd";
    ll = "${cfg.package}/bin/lsd -l";
    la = "${cfg.package}/bin/lsd -a";
    lt = "${cfg.package}/bin/lsd --tree";
    lla = "${cfg.package}/bin/lsd -la";
  };

in {
  options.programs.lsd = {
    enable = mkEnableOption "lsd";

    enableAliases = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable recommended lsd aliases.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.lsd;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    environment.shellAliases = mkIf cfg.enableAliases aliases;
  };
}
