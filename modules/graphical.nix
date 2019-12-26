{ config, lib, pkgs, ... }: {
    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio = {
        enable = true;
        support32Bit = true;
    };
    nixpkgs.config.pulseaudio = true;

    # Enable the X11 windowing system.
    services.xserver = {
        enable = true;
        layout = "us";
        libinput = {
            enable = true;
            accelProfile = "flat";
            accelSpeed = "0";
        };
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
    };
}
