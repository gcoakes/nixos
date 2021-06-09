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
    extraGroups = [ "input" "wheel" "audio" "networkmanager" "adbusers" ];
    openssh.authorizedKeys.keyFiles =
      [ ./ssh-laptop.pub ./ssh-workstation.pub ];
    initialPassword = "P@ssw0rd";
    packages = with pkgs; [
      cabal-install
      cargo
      cargo-edit
      discord
      ghc
      gimp
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
      qutebrowser
      rustc
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
      options = [ "compress=lzo" "discard" "noatime" "subvol=@" ];
    };

    "/home" = {
      label = "nixos";
      fsType = "btrfs";
      options = [ "compress=lzo" "discard" "noatime" "subvol=@home" ];
    };

    "/nix" = {
      label = "nixos";
      fsType = "btrfs";
      options = [ "compress=lzo" "discard" "noatime" "subvol=@nix" ];
    };

    "/var/log" = {
      label = "nixos";
      fsType = "btrfs";
      options = [ "compress=lzo" "discard" "noatime" "subvol=@log" ];
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

  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      pulseSupport = true;
      mpdSupport = true;
    };
    script = ''
      polybar top &
      polybar bottom &
    '';
    extraConfig = builtins.readFile ./polybar.ini;
    extraPackages = with pkgs;
      let
        mpris-meta = writeShellScriptBin "mpris-meta" ''
          playerctl -ls | while read player; do
            if [ "$(playerctl -sp "$player" status)" = Playing ]; then
              case "$player" in
                spotify*)  icon='' ;;
                mpv*)      icon='' ;;
                chromium*) icon='' ;;
                *)         icon='ﱘ' ;;
              esac
              printf '%s %s (%s)' \
                "$icon" \
                "$(playerctl -sp "$player" metadata title)" \
                "$(playerctl -sp "$player" metadata artist)"
              exit 0
            fi
          done
          echo
        '';
      in [ xmonad-log pulseaudio pavucontrol playerctl mpris-meta ];
  };

  services.picom = {
    enable = true;
    activeOpacity = 0.93;
    fade = true;
    inactiveOpacity = 0.8;
    opacityRules = [
      "100:_NET_WM_STATE@[0]:32a *= '_NET_WM_STATE_FULLSCREEN'"
      "100:_NET_WM_STATE@[1]:32a *= '_NET_WM_STATE_FULLSCREEN'"
      "100:_NET_WM_STATE@[2]:32a *= '_NET_WM_STATE_FULLSCREEN'"
      "100:_NET_WM_STATE@[3]:32a *= '_NET_WM_STATE_FULLSCREEN'"
      "100:_NET_WM_STATE@[4]:32a *= '_NET_WM_STATE_FULLSCREEN'"
      "100:class_g = 'brave-browser'"
      "50:class_g = 'polybar'"
    ];
    backend = "glx";
    shadow = true;
    shadowExclude = [ "window_type *= 'dock'" "class_g = 'Desktop'" ];
    settings = {
      no-fading-openclose = true;
      blur-background-exclude = [ "class_g = 'Polybar'" ];
      blur = {
        method = "dual_kawase";
        strength = 10;
        background = false;
        background-frame = false;
        background-fixed = false;
      };
    };
  };

  services.xserver.wallpaper = {
    enable = true;
    image = pkgs.fetchurl {
      url = "https://i.imgur.com/hyt5lCu.jpg";
      hash = "sha256-3+VH9tO1iOWIGzE97j1SLu8dmVbxq32/qBwlUT82ONc=";
    };
  };

  programs.xss-lock = {
    enable = true;
    extraOptions = [ "--transfer-sleep-lock" ];
    lockerCommand = let
      locker = pkgs.writeShellScript "locker" ''
        # We set a trap to kill the locker if we get killed, then start the locker and
        # wait for it to exit. The waiting is not that straightforward when the locker
        # forks, so we use this polling only if we have a sleep lock to deal with.
        if [[ -e /dev/fd/${"$"}{XSS_SLEEP_LOCK_FD:--1} ]]; then
            kill_i3lock() {
                pkill -xu $EUID "$@" i3lock
            }

            trap kill_i3lock TERM INT

            # we have to make sure the locker does not inherit a copy of the lock fd
            ${pkgs.i3lock-fancy}/bin/i3lock-fancy {XSS_SLEEP_LOCK_FD}<&-

            # now close our fd (only remaining copy) to indicate we're ready to sleep
            exec {XSS_SLEEP_LOCK_FD}<&-

            while kill_i3lock -0; do
                sleep 0.5
            done
        else
            trap 'kill %%' TERM INT
            i3lock -n &
            wait
        fi
      '';
    in "${locker}";
  };

  services.xserver.xautolock = {
    enable = true;
    locker = "/run/current-system/systemd/bin/systemctl suspend";
  };

  services.logind.lidSwitch = "suspend-then-hibernate";

  services.pass-secret-service.enable = true;

  #########################
  ######## Desktop ########
  #########################

  environment.etc."xdg/mimeapps.list".source = ./mimeapps.list;

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
      "core.pager" = "delta";
      "interactive.diffFilter" = "delta --color-only";
    };
    users.gcoakes.config = {
      "user.email" = "gregcoakes@gmail.com";
      "user.name" = "Gregory C. Oakes";
    };
    extraPackages = with pkgs; [ delta git-review git-crypt ];
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
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
