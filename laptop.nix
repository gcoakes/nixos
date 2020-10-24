{ config, lib, pkgs, ... }: {
  services.xserver.videoDrivers = [ "amdgpu" "radeon" ];

  networking.hostName = "laptop";
  networking.interfaces.enp4s0f3u2.useDHCP = true;
  networking.interfaces.wlp2s0.useDHCP = true;

  boot = {
    initrd = {
      availableKernelModules =
        [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ ];
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

