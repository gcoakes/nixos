{ pkgs, lib, inputs, ... }: {
  boot.wsl = {
    enable = true;
    user = "oakesgrx";
    etcNixos = lib.cleanSource ./.;
  };
  users.users.oakesgrx = {
    shell = pkgs.fish;
    isNormalUser = true;
  };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.oakesgrx = {
    imports = [ (import ./dev-env.nix { email = "gregoryx.oakes@intel.com"; inherit inputs; }) ];

    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    home.username = "oakesgrx";
    home.homeDirectory = "/home/oakesgrx";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home.stateVersion = "21.05";
  };
  networking.hostName = "nixos-wsl";
  networking.proxy = {
    default = "http://proxy-chain.intel.com:911";
    noProxy = "127.0.0.1,::1,localhost,.localdomain,.intel.com";
  };
}
