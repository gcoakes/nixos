with builtins;
{ config, pkgs, lib, inputs, ... }:
let
  gpsm = with pkgs;
    writeShellScriptBin "gpsm" ''
      store="$HOME/.password-store"
      ${findutils}/bin/find "$store" -name '.git*' -prune -o -type d -print \
      | ${gnused}/bin/sed "s|^$store/\(.*\)$|\1|" \
      | ${gnugrep}/bin/grep -v '^$' \
      | ${rofi}/bin/rofi -dmenu \
      | ${findutils}/bin/xargs ${pass}/bin/pass generate -c $@
    '';
  hidden-shell = with pkgs;
    writeShellScriptBin "hidden-shell" ''
      cat > shell.nix <<EOF
      with (builtins.getFlake flake:nixpkgs).legacyPackages.x86_64-linux;
      mkShell {
        nativeBuildInputs = [ $@ ];
        buildInputs = [];
      }
      EOF
      echo use nix > .envrc
      echo shell.nix >> .git/info/exclude
    '';
in {
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

  ####################################
  ######## User Configuration ########
  ####################################

  users.defaultUserShell = pkgs.zsh;
  users.users.gcoakes = {
    description = "Gregory C. Oakes";
    useDefaultShell = true;
    createHome = true;
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" "audio" "docker" "networkmanager" "adbusers" ];
    openssh.authorizedKeys.keyFiles =
      [ ./ssh-laptop.pub ./ssh-workstation.pub ];
    initialPassword = "P@ssw0rd";
    packages = with pkgs; [
      brave
      cargo
      cargo-edit
      gimp
      git-review
      gpsm
      hidden-shell
      ipfs
      kitty
      kubectl
      kubernetes-helm
      libreoffice
      pass
      pavucontrol
      poetry
      spotify
      unzip
      vscodium
      xclip
      yarn
      zip
    ];
  };

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

  services.picom = {
    enable = true;
    activeOpacity = 0.85;
    fade = true;
    inactiveOpacity = 0.8;
    opacityRules = [
      "100:class_g = 'brave-browser'"
      "100:class_g = 'Desktop'"
      "50:class_g = 'polybar'"
    ];
  };

  services.pass-secret-service.enable = true;

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
          ${pkgs.xmonad-config}/bin/xmonad-config &
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

  ##########################
  ######## Security ########
  ##########################

  security.pki.certificates =
    [ (builtins.readFile "${inputs.dod-pki}/DoD_PKE_CA_chain.pem") ];

  security.chromiumSuidSandbox.enable = true;

  environment.variables.npm_config_ignore_scripts = "true";

  ##########################
  ######## Programs ########
  ##########################

  nixpkgs.overlays = import ./overlays inputs;

  environment.systemPackages = with pkgs; [ vulkan-loader ];

  programs.dconf.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "gtk2";
    enableSSHSupport = true;
  };

  programs.git = {
    enable = true;
    config = {
      "init.defaultBranch" = "main";
      "core.excludesfile" = pkgs.writeText "gitignore" ''
        .direnv/
        .vscode/
        .envrc
      '';
      "core.pager" = "${pkgs.delta}/bin/delta";
      "interactive.diffFilter" = "${pkgs.delta}/bin/delta --color-only";
    };
    users.gcoakes.config = {
      "user.email" = "gregcoakes@gmail.com";
      "user.name" = "Gregory C. Oakes";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    shellInit = ''
      if test -z "$DISPLAY" || ! command -v codium 1>/dev/null 2>&1; then
        export EDITOR=nvim
      else
        export EDITOR="codium --wait"
      fi
    '';
    ohMyZsh = {
      enable = true;
      theme = "fino-time";
      plugins = [ "colored-man-pages" ];
    };
    syntaxHighlighting.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.lesspipe.enable = true;

  programs.lsd.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure = {
      customRC = builtins.readFile ./init.vim;
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [ dracula-vim fzf-vim lightline-vim vim-nix vim-rooter ];
      };
    };
    viAlias = true;
    vimAlias = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

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
