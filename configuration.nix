with builtins;
{ config, pkgs, ... }: {
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./graphical.nix
    ./cachix.nix
  ];

  ####################################
  ######## User Configuration ########
  ####################################

  programs.fish = {
    enable = true;
    vendor = {
      functions.enable = true;
      config.enable = true;
      completions.enable = true;
    };
  };

  users.users.gcoakes = {
    shell = pkgs.fish;
    createHome = true;
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "docker" "networkmanager" "adbusers" ];
  };

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
    authorizedKeysFiles = [ ".config/ssh/authorized_keys" ];
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

  environment.systemPackages = with pkgs; [
    git
    cachix
  ];

  system = {
    autoUpgrade.enable = true;
  };
  nix.gc.automatic = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03";

  ########################################
  ######## Hardware Configuration ########
  ########################################

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "workstation";
  networking.networkmanager.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp7s0.useDHCP = true;
  networking.interfaces.wlp6s0.useDHCP = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
    configFile = pkgs.runCommand "default.pa" {} ''
      sed 's/module-udev-detect$/module-udev-detect tsched=0/' \
          ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
      echo 'load-module module-bluetooth-policy' >> $out
      echo 'load-module module-bluetooth-discover' >> $out
    '';
  };

  services.xserver.dpi = 120;

  environment.variables = {
    WINIT_HIDPI_FACTOR = "1.7";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot = {
    supportedFilesystems = [ "btrfs" ];
    initrd = {
      supportedFilesystems = [ "btrfs" ];
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/1436a8d5-fbfc-4c46-941b-28b2eddc3b7a";
      fsType = "btrfs";
      options = [ "compress=lzo,discard,noatime,subvol=@" ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/1436a8d5-fbfc-4c46-941b-28b2eddc3b7a";
      fsType = "btrfs";
      options = [ "compress=lzo,discard,noatime,subvol=@home" ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/1436a8d5-fbfc-4c46-941b-28b2eddc3b7a";
      fsType = "btrfs";
      options = [ "compress=lzo,discard,noatime,subvol=@nix" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/CC42-1ECC";
      fsType = "vfat";
    };

    "/mnt/data" = {
      device = "/dev/disk/by-uuid/26fb826f-2cc2-4c64-afd4-1245c20f1095";
      fsType = "ext4";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/df0c60c6-5b1f-46ca-a417-418f4ab1ab72"; }
  ];
  hardware = {
    cpu.amd.updateMicrocode = true;
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
  };

  nix.maxJobs = 16;
}
