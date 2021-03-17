with builtins;
{ pkgs, inputs, ... }: {
  ###########################################
  ######## System Package Management ########
  ###########################################

  nix.gc.automatic = true;
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "21.05";

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config.allowUnfree = true;

  ######################
  ######## Misc ########
  ######################

  time.timeZone = "US/Central";
}
