with builtins;
let
  # There's a bug in builtins.readFile which prevents it from reading sysfs
  # files.
  productUuidHash =
    builtins.hashFile "md5" /sys/devices/virtual/dmi/id/product_uuid;
  systemName = builtins.getAttr productUuidHash {
    "5f90cc144722d859b5eff64fc7883e34" = "laptop";
    "f625c25ec3042336db5fe1d4b821deb6" = "workstation";
  };
in { config, pkgs, ... }:
let
  dodPki = pkgs.fetchzip {
    url =
      "https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/certificates_pkcs7_v5-10_wcf.zip";
    sha256 = "1sjkgbpi0d032xgnhx1zi1liqmaxwln8vr2kf512hnq1izk19vcq";
  };
in {
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./graphical.nix
    (./. + "/${systemName}.nix")
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
    openssh.authorizedKeys.keyFiles =
      [ ./ssh-laptop.pub ./ssh-workstation.pub ];
  };

  programs.adb.enable = true;

  ##########################
  ######## Serivces ########
  ##########################

  # Allow yubikeys to be accessible.
  services.udev.packages = with pkgs; [
    android-udev-rules
    yubikey-personalization
    ledger-udev-rules
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

  services.ipfs = {
    enable = true;
    dataDir = "/var/lib/ipfs";
    autoMount = true;
    enableGC = true;
    extraFlags = [ "--enable-pubsub-experiment" ];
    extraConfig.Pubsub = {
      Router = "gossipsub";
      DisableSigning = false;
    };
  };

  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  virtualisation.docker.enable = true;

  ######################
  ######## Misc ########
  ######################

  nixpkgs.config.allowUnfree = true;
  time.timeZone = "US/Central";

  security.pki.certificates =
    [ (builtins.readFile "${dodPki}/DoD_PKE_CA_chain.pem") ];

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
  networking.hostName = systemName;

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
