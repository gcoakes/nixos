# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }: {
    imports = [
        # Include the results of the hardware scan.
        ./hardware-configuration.nix
        ./modules/graphical.nix
        ./modules/common.nix
    ];

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "workstation"; # Define your hostname.
    networking.networkmanager.enable = true;

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;
    networking.interfaces.enp7s0.useDHCP = true;
    networking.interfaces.wlp6s0.useDHCP = true;

    services.xserver.dpi = 120;

    environment.variables =
      { WINIT_HIDPI_FACTOR = "1.5";
      };

    system.stateVersion = "20.03";
}

