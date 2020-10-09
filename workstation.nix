{ config, lib, pkgs, ... }: {
  services.xserver = {
    videoDrivers = [ "amdgpu" "radeon" ];
    xrandrHeads = [
      {
        output = "DisplayPort-2";
        primary = true;
      }
      "HDMI-A-0"
    ];
  };

  virtualisation.libvirtd.enable = true;

  networking.hostName = "workstation";
  networking.interfaces.enp7s0.useDHCP = true;
  networking.interfaces.wlp6s0.useDHCP = true;

  services.xserver.dpi = 120;
  environment.variables = { WINIT_HIDPI_FACTOR = "1.7"; };

  boot = {
    supportedFilesystems = [ "btrfs" ];
    initrd = {
      supportedFilesystems = [ "btrfs" ];
      availableKernelModules =
        [ "vfio-pci" "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ ];
      preDeviceCommands = ''
        DEVS="0000:01:00.0"
        for DEV in $DEVS; do
          echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
        done
        modprobe -i vfio-pci
        '';
    };
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "amd_iommu=on" "pcie_aspm=off" ];
    extraModulePackages = [ ];
  };

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

    "/var/lib/docker" = {
      device = "/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_18JOK5H4FSAA";
      fsType = "btrfs";
      options = [
        "device=/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_18JOK5H4FSAA"
        "device=/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_28QIKI8WFSAA"
        "noatime"
        "subvol=@docker"
      ];
    };

    "/mnt/data" = {
      device = "/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_18JOK5H4FSAA";
      fsType = "btrfs";
      options = [
        "device=/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_18JOK5H4FSAA"
        "device=/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_28QIKI8WFSAA"
        "compress=lzo"
        "noatime"
        "subvol=@data"
      ];
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
  };

  nix.maxJobs = 16;
}

