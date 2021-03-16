with builtins;
{ pkgs, ... }: {
  ####################################
  ######## User Configuration ########
  ####################################

  users.users.gcoakes = {
    shell = pkgs.zsh;
    createHome = true;
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "docker" "networkmanager" "adbusers" ];
    openssh.authorizedKeys.keyFiles =
      [ ./ssh-laptop.pub ./ssh-workstation.pub ];
  };

  ###########################################
  ######## System Package Management ########
  ###########################################

  nix.gc.automatic = true;

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
