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

  boot.initrd.luks.devices = [
    { name = "cryptnix";
      device = "/dev/disk/by-uuid/2cd8df23-2186-4ab8-98ca-91f422e29b5c";
      allowDiscards = true;
    }
  ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/dbfbfb2e-c275-4ba8-83d1-f638186b2623";
      fsType = "btrfs";
      options = [ "discard,noatime,compress=lzo,subvol=@nix" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6B23-54B9";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-partuuid/f3e35a68-8f10-410a-8070-11846273c40a";
        encrypted.label = "nixswap";
        randomEncryption.enable = true; }
    ];

  nix.maxJobs = lib.mkDefault 8;
}
