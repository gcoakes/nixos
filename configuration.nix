with builtins;
{ config, pkgs, ... }: {
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./graphical.nix
    ./laptop.nix
  ];

  #############################
  ######## Filesystems ########
  #############################

  fileSystems = {
    "/" = {
      label = "nixos";
      fsType = "btrfs";
      options = [ "compress=lzo,discard,noatime,subvol=@" ];
    };

    "/home" = {
      label = "nixos";
      fsType = "btrfs";
      options = [ "compress=lzo,discard,noatime,subvol=@home" ];
    };

    "/nix" = {
      label = "nixos";
      fsType = "btrfs";
      options = [ "compress=lzo,discard,noatime,subvol=@nix" ];
    };

    "/boot" = {
      label = "boot";
      fsType = "vfat";
    };
  };

  swapDevices = [ { label = "swap"; } ];

  boot = {
    supportedFilesystems = [ "btrfs" ];
    initrd.supportedFilesystems = [ "btrfs" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1
    '';
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  ####################################
  ######## User Configuration ########
  ####################################

  users.users.gcoakes = {
    shell = pkgs.zsh;
    createHome = true;
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "docker" "networkmanager" "adbusers" ];
    openssh.authorizedKeys.keyFiles = [ ./ssh-laptop.pub ./ssh-workstation.pub ];
  };

  programs.adb.enable = true;

  ##########################
  ######## Serivces ########
  ##########################

  # Allow yubikeys to be accessible.
  services.udev.packages = with pkgs; [
    android-udev-rules
    yubikey-personalization
  ];

  # Enable using smart cards.
  services.pcscd.enable = true;

  # Enable ssh connections from my smart card.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
    permitRootLogin = "no";
    ports = [ 2222 ];
  };

  virtualisation.docker.enable = true;

  ######################
  ######## Misc ########
  ######################

  nixpkgs.config.allowUnfree = true;
  time.timeZone = "US/Central";

  ###########################################
  ######## System Package Management ########
  ###########################################

  environment.systemPackages = with pkgs; [ git cachix vulkan-loader ];

  system = { autoUpgrade.enable = true; };
  nix.gc.automatic = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.09";

  ########################################
  ######## Hardware Configuration ########
  ########################################

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
    configFile = pkgs.runCommand "default.pa" { } ''
      sed 's/module-udev-detect$/module-udev-detect tsched=0/' \
          ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
      echo 'load-module module-bluetooth-policy' >> $out
      echo 'load-module module-bluetooth-discover' >> $out
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages;
}
