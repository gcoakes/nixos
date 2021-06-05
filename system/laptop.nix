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
