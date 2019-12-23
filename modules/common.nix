{ config, lib, pkgs, ... }: {
    programs.zsh.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.gcoakes = {
        shell = pkgs.zsh;
        createHome = true;
        isNormalUser = true;
        group = "users";
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    };

    # Set your time zone.
    time.timeZone = "America/Los_Angeles";

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment = {
        systemPackages = with pkgs; [
            git
            wget
            htop
            neovim
        ];
        variables = {
            EDITOR = "nvim";
            PAGER = "less";
        };
    };

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "19.09"; # Did you read the comment?
}
