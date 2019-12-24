# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
    imports = [
        # Include the results of the hardware scan.
        ./hardware-configuration.nix
        ./modules/graphical.nix
        ./modules/common.nix
    ];


    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "oakesgrx-dev";

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;
    networking.interfaces.eno1.useDHCP = true;

    # Configure network proxy if necessary
    networking.proxy.default = "http://proxy-chain.intel.com:911/";
    networking.proxy.noProxy = "127.0.0.1,localhost,::1,*.intel.com";

    # Configure sshd
    services.openssh.enable = true;

    # Configure docker.
    virtualisation.docker.enable = true;
}

