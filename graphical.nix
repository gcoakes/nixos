{ config, lib, pkgs, ... }: {
  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
  };
  nixpkgs.config.pulseaudio = true;

  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts.monospace = [ "FuraCode Nerd Font" ];
    };
    fonts = with pkgs; [
      nerdfonts
    ];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "us";
    libinput = {
      enable = true;
      accelProfile = "flat";
      accelSpeed = "0";
    };
    videoDrivers = [ "amdgpu" "radeon" ];
    xrandrHeads = [
      { output = "DisplayPort-1"; monitorConfig = ''Option "Rotate" "left"''; }
      { output = "DisplayPort-2"; primary = true; }
      "HDMI-A-0"
    ];
    desktopManager = {
      xterm.enable = false;
      session = [
        {
          name = "home-manager";
          bgSupport = true;
          start = ''
            ${pkgs.runtimeShell} $HOME/.hm-xsession &
            waitPID=$!
          '';
        }
      ];
    };
    displayManager.lightdm = {
      enable = true;
      greeters.enso = {
        enable = true;
        cursorTheme.package = pkgs.capitaine-cursors;
      };
    };
    serverFlagsSection = ''
      Option "DontVTSwitch" "True"
    '';
  };
}
