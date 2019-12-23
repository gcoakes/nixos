{ config, lib, pkgs, ... }: {
    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # Enable the X11 windowing system.
    services.xserver = {
        enable = true;
        layout = "us";
        desktopManager = {
            default = "pantheon";
            xterm.enable = false;
            pantheon.enable = true;
            session = [
                {
                    name = "home-manager";
                    start = ''
                        ${pkgs.runtimeShell} $HOME/.hm-xsession &
                        waitPID=$!
                    '';
                }
            ];
        };
        displayManager.lightdm.enable = true;
        videoDrivers = [ "amd" ];
    };
}
