# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }: {
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.initrd.supportedFilesystems = [ "btrfs" ];

  boot.initrd.luks.devices."cryptnix" =
    { device = "/dev/disk/by-uuid/2cd8df23-2186-4ab8-98ca-91f422e29b5c";
      allowDiscards = true;
    };

  fileSystems."/" =
    { device = "/dev/mapper/cryptnix";
      fsType = "btrfs";
      options = [ "discard,noatime,compress=lzo,subvol=nixos" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6B23-54B9";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-partuuid/0b066fa6-e35c-da41-8041-a22d4d8ab50d";
        encrypted.label = "nixswap";
        randomEncryption.enable = true;
      }
    ];

  services.xserver.videoDrivers = [ "amdgpu" "radeon" ];
  hardware =
    { cpu.amd.updateMicrocode = true;
      opengl =
        { enable = true;
          driSupport32Bit = true;
        };
    };

  nix.maxJobs = lib.mkDefault 8;
}
