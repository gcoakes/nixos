{ pkgs, config, lib, ... }:

with lib;

let cfg = config.services.pass-secret-service;
in {
  options.services.pass-secret-service = {
    enable = mkEnableOption "Pass libsecret service";
    package = mkOption {
      type = types.package;
      default = pkgs.pass-secret-service;
    };
    path = mkOption {
      type = types.str;
      default = "%h/.password-store";
    };
  };
  config = mkIf cfg.enable {
    systemd.user.services.pass-secret-service = {
      enable = true;
      description = "Pass libsecret service";
      script = "${cfg.package}/bin/pass_secret_service --path '${cfg.path}'";
      wantedBy = [ "default.target" ];
    };
  };
}
