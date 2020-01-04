let
    gcoakes-nixhome =
        if builtins.pathExists ("/home/gcoakes/.config/nixpkgs/home.nix") then (
            "/home/gcoakes/.config/nixpkgs/home.nix"
        ) else (
            builtins.fetchGit {
              url = https://gitlab.com/gcoakes/nixhome.git;
              name = "gcoakes-nixhome";
            } + "/home.nix"
        );
    home-manager = builtins.fetchTarball {
        url = https://github.com/rycee/home-manager/archive/release-19.09.tar.gz;
    };
in { config, lib, pkgs, ... }: {
    imports = [
        "${home-manager}/nixos"
    ];

    boot.kernelPackages = pkgs.linuxPackages_latest;

    programs.zsh.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.gcoakes = {
        shell = pkgs.zsh;
        createHome = true;
        isNormalUser = true;
        extraGroups = [ "wheel" "audio" "docker" "networkmanager" ];
    };

    home-manager.users.gcoakes = import gcoakes-nixhome;

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
    system = {
        autoUpgrade.enable = true;
    };

    # Allow yubikeys to be accessible.
    services.udev.packages = with pkgs; [
        yubikey-personalization
    ];

    # Enable using smart cards.
    services.pcscd.enable = true;

    # Enable ssh connections from my smart card.
    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
      permitRootLogin = "no";
      ports = [ 2222 ];
      authorizedKeysFiles = [ ".config/ssh/authorized_keys" ];
    };
}
