{ config, lib, pkgs, ... }: {
  services.xserver = {
    videoDrivers = [ "amdgpu" "radeon" ];
    libinput = {
      enable = true;
      calibrationMatrix = "2.4 0 0 0 2.4 0 0 0 1";
      accelProfile = "flat";
      tapping = true;
      dev = "/dev/input/event14";
    };
  };

  networking.dhcpcd.wait = "background";
  networking.interfaces.wlp2s0.useDHCP = true;

  swapDevices = [ { label = "swap"; } ];

  boot = {
    initrd = {
      availableKernelModules =
        [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [];
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
    sensor.iio.enable = true;
  };
}
