with builtins;
{ config, pkgs, inputs, ... }:
let xmonad-config = pkgs.haskellPackages.callPackage ./xmonad { };
in {
  ####################################
  ######## User Configuration ########
  ####################################

  users.users.gcoakes = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "docker" "networkmanager" "adbusers" ];
    openssh.authorizedKeys.keyFiles =
      [ ./ssh-laptop.pub ./ssh-workstation.pub ];
    initialPassword = "P@ssw0rd";
  };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.gcoakes = import ./home.nix inputs;

  users.users.root.openssh.authorizedKeys.keyFiles =
    [ ./ssh-laptop.pub ./ssh-workstation.pub ];

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

  services.picom = {
    enable = true;
    activeOpacity = 0.85;
    fade = true;
    inactiveOpacity = 0.8;
    opacityRules = [ "100:class_g = 'brave-browser'" "50:class_g = 'polybar'" ];
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
      defaultFonts.monospace = [ "FiraCode Nerd Font Mono" ];
    };
    fonts = [ (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; }) ];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager = {
      defaultSession = "none+xmonad";
      lightdm = {
        enable = true;
        greeters.mini = {
          enable = true;
          user = "gcoakes";
          extraConfig = ''
            [greeter]
            show-password-label = false
            [greeter-theme]
            font = "FiraCode Nerd Font Mono"
            background-image = ""
            text-color = "#f8f8f2"
            error-color = "#ff5555"
            background-color = "#282a36"
            window-color = "#44475a"
            border-color = "#6272a4"
            password-color = "#f8f8f2"
            password-background-color = "#282a36"
            password-border-color = "#6272a4"
          '';
        };
        extraSeatDefaults = ''
          user-session = ${config.services.xserver.displayManager.defaultSession}
        '';
      };
      session = [{
        manage = "window";
        name = "xmonad";
        start = ''
          ${xmonad-config}/bin/xmonad-config &
          waitPID=$!
        '';
      }];
    };
    desktopManager.xterm.enable = false;
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

  programs.dconf.enable = true;

  programs.gnupg.agent.pinentryFlavor = "gtk";

  security.chromiumSuidSandbox.enable = true;

  ######################
  ######## Misc ########
  ######################

  security.pki.certificates =
    [ (builtins.readFile "${inputs.dod-pki}/DoD_PKE_CA_chain.pem") ];

  ###########################################
  ######## System Package Management ########
  ###########################################

  environment.systemPackages = with pkgs; [ git cachix vulkan-loader gcr ];

  ########################################
  ######## Hardware Configuration ########
  ########################################

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
    configFile = pkgs.runCommand "default.pa" { } ''
      sed 's/module-udev-detect$/module-udev-detect tsched=0/' \
          ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
      echo 'load-module module-bluetooth-policy' >> $out
      echo 'load-module module-bluetooth-discover' >> $out
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableAllFirmware = true;
}
