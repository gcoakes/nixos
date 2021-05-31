{ pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
  ];

  system.stateVersion = "21.11";

  environment.systemPackages = with pkgs; [ nixFlakes tmux git cryptsetup ];

  # Allow sudo without password, if the user is using an authorized ssh key.
  security.sudo.enable = true;
  security.pam.enableSSHAgentAuth = true;

  # User management.
  users.users.nixos = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles =
      [ ./ssh-workstation.pub ./ssh-laptop.pub ];
  };

  # Enable login from workstation.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
}
