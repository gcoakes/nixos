{ pkgs, lib, ... }: {
  boot.wsl = {
    enable = true;
    user = "oakesgrx";
    etcNixos = lib.cleanSource ./.;
  };
  users.users.oakesgrx = {
    shell = pkgs.zsh;
    isNormalUser = true;
  };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.oakesgrx = import ./wsl-home.nix;
  networking.hostName = "nixos-wsl";
  networking.proxy = {
    default = "http://proxy-chain.intel.com:911";
    noProxy = "127.0.0.1,::1,localhost,.localdomain,.intel.com";
  };
}
