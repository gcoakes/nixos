with builtins;
{ config, pkgs, inputs, ... }: {
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
    supportedFilesystems = [ "btrfs" "ntfs" ];
    initrd.supportedFilesystems = [ "btrfs" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1
    '';
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

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

  #########################
  ######## Desktop ########
  #########################

  sound.enable = true;

  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts.monospace = [ "Hasklug Nerd Font Complete" ];
    };
    fonts = [ (pkgs.nerdfonts.override { fonts = [ "Hasklig" ]; }) ];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome3.enable = true;
    videoDrivers = [ "amdgpu" "radeon" ];
    layout = "us";
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";
        accelSpeed = "0";
      };
    };
  };

  environment.gnome3.excludePackages = with pkgs.gnome3; [
    epiphany
    geary
    gedit
    gnome-terminal
    seahorse
    yelp
  ];

  programs.gnupg.agent.pinentryFlavor = "gnome";

  programs.dconf.enable = true;

  security.chromiumSuidSandbox.enable = true;

  ######################
  ######## Misc ########
  ######################

  security.pki.certificates =
    [ (builtins.readFile "${inputs.dod-pki}/DoD_PKE_CA_chain.pem") ];

  programs.adb.enable = true;

  ###########################################
  ######## System Package Management ########
  ###########################################

  environment.systemPackages = with pkgs; [ git cachix vulkan-loader ];

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
    support32Bit = true;
    package = pkgs.pulseaudioFull;
    configFile = pkgs.runCommand "default.pa" {} ''
      sed 's/module-udev-detect$/module-udev-detect tsched=0/' \
          ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
      echo 'load-module module-bluetooth-policy' >> $out
      echo 'load-module module-bluetooth-discover' >> $out
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableAllFirmware = true;
}
