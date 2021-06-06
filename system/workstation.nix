{ config, lib, pkgs, ... }: {
  virtualisation.libvirtd.enable = true;

  networking.hostName = "workstation";

  boot = {
    supportedFilesystems = [ "btrfs" "ntfs" ];
    initrd = {
      supportedFilesystems = [ "btrfs" ];
      availableKernelModules = [ "nvme" "btrfs" ];
      luks.devices.nixos = {
        device = "/dev/disk/by-uuid/78a82fff-45d1-4f08-8dac-46f111c35f29";
        allowDiscards = true;
        bypassWorkqueues = true;
      };
    };
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "amd_iommu=on" "pcie_aspm=off" ];
    kernel.sysctl = { "vm.nr_hugepages" = "64"; };
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

    "/var/lib/ipfs" = {
      device = "/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_18JOK5H4FSAA";
      fsType = "btrfs";
      options = [
        "device=/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_18JOK5H4FSAA"
        "device=/dev/disk/by-id/ata-TOSHIBA_MD04ACA400_28QIKI8WFSAA"
        "compress=lzo"
        "noatime"
        "subvol=@ipfs"
      ];
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    opengl = {
      enable = true;
      extraPackages = with pkgs; [ rocm-opencl-icd amdvlk ];
      extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];
      driSupport32Bit = true;
    };
  };

  environment.variables.VK_ICD_FILENAMES =
    "/run/opengl-driver/share/vulkan/icd.d/amd_icd64.json";

  services.xserver = {
    xrandrHeads = [
      {
        output = "DisplayPort-1";
        primary = true;
      }
      {
        output = "DisplayPort-2";
        monitorConfig = ''Option "Rotate" "right"'';
      }
    ];
    wallpaper.live = {
      enable = true;
      url = "https://www.youtube.com/watch?v=sNZKRC_E8xY";
    };
  };
}
