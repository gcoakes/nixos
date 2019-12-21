# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }: {
    imports = [
        # Include the results of the hardware scan.
        ./hardware-configuration.nix
    ];

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # networking.hostName = "nixos"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;
    networking.interfaces.enp7s0.useDHCP = true;

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Select internationalisation properties.
    # i18n = {
    #   consoleFont = "Lat2-Terminus16";
    #   consoleKeyMap = "us";
    #   defaultLocale = "en_US.UTF-8";
    # };

    # Set your time zone.
    time.timeZone = "America/Los_Angeles";

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
        git
        wget
        htop
        dmenu
        neovim
        qutebrowser
    ];

    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;

    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # Enable the X11 windowing system.
    services.xserver = {
        enable = true;
        layout = "us";
        windowManager = {
          xmonad.enable = true;
          xmonad.enableContribAndExtras = true;
          default = "xmonad";
        };
        desktopManager.default = "none";
        displayManager.lightdm.enable = true;
        videoDrivers = [ "amd" ];
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.gcoakes = {
        createHome = true;
        isNormalUser = true;
        group = "users";
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    };

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "19.09"; # Did you read the comment?

}

