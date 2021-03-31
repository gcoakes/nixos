{ pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  # Enable login from workstation.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
    permitRootLogin = "no";
  };

  # Allow sudo without password, if the user is using an authorized ssh key.
  security.sudo.enable = true;
  security.pam.enableSSHAgentAuth = true;

  # User management.
  users.users.gcoakes = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles =
      [ ./ssh-workstation.pub ./ssh-laptop.pub ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  security.acme = {
    acceptTerms = true;
    email = "gregcoakes@gmail.com";
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    virtualHosts = {
      "cloud.oakes.family" = {
        forceSSL = true;
        enableACME = true;
      };
    };
  };

  services.nextcloud = {
    enable = true;
    hostName = "cloud.oakes.family";
    https = true;
    autoUpdateApps.startAt = "05:00:00";
    config = {
      overwriteProtocol = "https";
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      dbpassFile = "/var/nextcloud-db-pass";
      adminuser = "admin";
      adminpassFile = "/var/nextcloud-admin-pass";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }
    ];
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  fileSystems."/var".label = "data";
}
