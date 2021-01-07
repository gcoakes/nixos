{ config, lib, pkgs, ... }: {
  services.xserver = {
    videoDrivers = [ "amdgpu" "radeon" ];
    xrandrHeads = [
      { output = "HDMI-A-0"; }
      {
        output = "DisplayPort-2";
        primary = true;
      }
    ];
  };

  virtualisation.libvirtd.enable = true;

  networking.interfaces.enp7s0.useDHCP = true;
  networking.interfaces.wlp6s0.useDHCP = true;

  boot = {
    initrd = {
      availableKernelModules =
        [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "amd_iommu=on" "pcie_aspm=off" ];
  };

  fileSystems = {
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
}

