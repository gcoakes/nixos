{ lib, pkgs, config, ... }:
with lib;
let cfg = config.entertainment;
in {
  options.entertainment = {
    enable = mkEnableOption "entertainment";
  };

  config = lib.mkIf cfg.enable {
    users.users."gcoakes".packages = with pkgs; [
      steam
    ];
  };
}
