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

  swapDevices = [{ label = "swap"; }];

  boot = {
    initrd = {
      supportedFilesystems = [ "btrfs" ];
      availableKernelModules = [ "nvme" "btrfs" ];
      luks = {
        reusePassphrases = true;
        gpgSupport = true;
        devices = let
          addCommon = label: device: {
            inherit device;
            preLVM = true;
            allowDiscards = true;
            bypassWorkqueues = true;
            gpgCard = {
              encryptedPass = ../luks-passphrase.asc;
              publicKey = ../public.asc;
            };
          };
        in lib.mapAttrs addCommon {
          nixos =
            "/dev/disk/by-id/nvme-SKHynix_HFS256GD9TNG-L3A0B_AD99N802310409U50-part2";
          swap =
            "/dev/disk/by-id/nvme-SKHynix_HFS256GD9TNG-L3A0B_AD99N802310409U50-part3";
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
