{ config, lib, pkgs, ... }: {
  services.xserver = {
    libinput = {
      touchpad = {
        accelProfile = "adaptive";
        tapping = true;
      };
    };
    xautolock.time = 1;
  };

  networking.hostName = "laptop";
  networking.dhcpcd.wait = "background";

  swapDevices = [{
    encrypted = {
      enable = true;
      blkDev =
        "/dev/disk/by-id/nvme-SKHynix_HFS256GD9TNG-L3A0B_AD99N802310409U50-part3";
      # /mnt-root is the location where / will be mounted in stage 1.
      keyFile = "/mnt-root/.swap-keyfile";
      # This is the /dev/mapper/<label> not the filesystem level label.
      label = "swap";
    };
    # Filesystem label.
    label = "swap";
  }];

  boot = {
    initrd = {
      supportedFilesystems = [ "btrfs" ];
      availableKernelModules = [ "nvme" "btrfs" ];
      luks = {
        gpgSupport = true;
        devices.nixos = {
          device =
            "/dev/disk/by-id/nvme-SKHynix_HFS256GD9TNG-L3A0B_AD99N802310409U50-part2";
          allowDiscards = true;
          bypassWorkqueues = true;
          gpgCard = {
            encryptedPass = ../luks-passphrase.asc;
            publicKey = ../public.asc;
          };
        };
      };
    };
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "amd_iommu=on" ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
  };
}
