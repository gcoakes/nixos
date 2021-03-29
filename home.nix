inputs:
{ config, pkgs, lib, nixosConfig, ... }:
let
  hasBattery = nixosConfig.networking.hostName == "laptop";
  haskligFont = pkgs.nerdfonts.override { fonts = [ "Hasklig" ]; };
  gpsm = with pkgs;
    writeShellScriptBin "gpsm" ''
      ${findutils}/bin/find ~/.password-store/ -name '.git*' -prune -o -type d -print \
      | ${gnused}/bin/sed "s|^$HOME/\.password-store/\(.*\)$|\1|" \
      | ${gnugrep}/bin/grep -v '^$' \
      | ${dmenu}/bin/dmenu \
      | ${findutils}/bin/xargs ${pass}/bin/pass generate -c $@
    '';
  psm = with pkgs;
    writeShellScriptBin "psm" ''
      ${findutils}/bin/find ~/.password-store/ -name '*.gpg' \
      | ${gnused}/bin/sed "s|^$HOME/\.password-store/\(.*\)\.gpg$|\1|" \
      | ${dmenu}/bin/dmenu \
      | ${findutils}/bin/xargs ${pass}/bin/pass show -c"${"\${1-1}"}"
    '';
  wallpapers = builtins.map builtins.fetchurl [
    { url = "https://i.redd.it/u5wugt3u42761.png"; sha256 = "12g7q1lkkawmswh3xa6lq1cjyxcdck2yvq2xipcrh1lq2s8g0xsp"; }
    { url = "https://i.imgur.com/hyt5lCu.jpg"; sha256 = "1mrq6qzm298wm2zpvaziascivvrfa8yywg9i3f4fb25msgv4grfz"; }
    { url = "https://i.imgur.com/cDvIVbE.jpg"; sha256 = "0xrdcgmbyf1zhi96qmrmfnsc85w47frjk8abbdlgkvwram75cqlw"; }
    { url = "https://i.imgur.com/eozPPEI.jpg"; sha256 = "05qinkfw8giqn1qcy1zz4fdx6gs72iq883nxx4diya8x24vgls2v"; }
  ];
  wallpapersDirectory = pkgs.linkFarm "wallpapers"
    (builtins.map (w: { name = builtins.baseNameOf w; path = w; }) wallpapers);
in
{
  imports = [ (import ./dev-env.nix { email = "gregcoakes@gmail.com"; inherit inputs; }) ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "gcoakes";
  home.homeDirectory = "/home/gcoakes";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";

  home.packages = with pkgs; [
    brave
    cachix
    ccid
    dmenu
    ffmpeg
    gimp
    gpsm
    ipfs
    libreoffice
    neovim-remote
    opensc
    pass
    pavucontrol
    psm
    haskligFont
    spotify
    unzip
    xclip
    yarn
    zip
    zstd
  ];

  programs = {
    gpg.enable = true;
    noti.enable = true;
    kitty = {
      enable = true;
      font = {
        name = "Hasklug Nerd Font Complete";
        package = haskligFont;
      };
      settings.enable_audio_bell = "no";
      extraConfig = ''
        include ${inputs.kitty-themes}/themes/Dracula.conf
      '';
    };
    zathura.enable = true;
  };
  services = {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 86400;
      enableSshSupport = true;
      sshKeys = [ "3310F4B460D1579E7BAD6684D9E9B9083B574282" ];
    };
    random-background = {
      enable = true;
      interval = "1h";
      imageDirectory = "${wallpapersDirectory}";
    };
  };
  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = [ "nvim.desktop" ];
        "text/x-script.python" = [ "nvim.desktop" ];
        "text/x-script.sh" = [ "nvim.desktop" ];
        "text/html" = [ "nvim.desktop" ];
        "text/css" = [ "nvim.desktop" ];
        "text/xml" = [ "nvim.desktop" ];
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        "application/x-pdf" = [ "org.pwmt.zathura.desktop" ];
        "x-scheme-handler/http" = [ "brave-browser.desktop" ];
        "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        "x-scheme-handler/about" = [ "brave-browser.desktop" ];
        "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
      };
    };
  };

  fonts.fontconfig.enable = true;

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-standard;
    };
  };

  home.activation = {
    passwordStoreDownload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      test -d "$HOME/.password-store" \
      || $DRY_RUN_CMD git clone git@gitlab.com:gcoakes/password-store.git $HOME/.password-store
    '';
    dodPki = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! ${pkgs.nssTools}/bin/modutil -dbdir "sql:$HOME/.pki/nssdb" -list | grep -q '^[[:space:]]*[[:digit:]]\+\. CAC Module'; then
        echo "Adding CAC Module to NSS."
        $DRY_RUN_CMD ${pkgs.nssTools}/bin/modutil -dbdir "sql:$HOME/.pki/nssdb" \
        -add "CAC Module" -libfile "$HOME/.nix-profile/lib/opensc-pkcs11.so" \
        && $DRY_RUN_CMD ${pkgs.nssTools}/bin/modutil -dbdir "sql:$HOME/.pki/nssdb" -list \
        | grep -q '^[[:space:]]*[[:digit:]]\+\. CAC Module'
      fi

      if ! ${pkgs.nssTools}/bin/certutil -d "sql:$HOME/.pki/nssdb" -L -n "${inputs.dod-pki}/DoD_PKE_CA_chain.pem"; then
        echo "Installing DoD PKI Certificates."
        $DRY_RUN_CMD ${pkgs.nssTools}/bin/certutil -d "sql:$HOME/.pki/nssdb" -A -t TC \
        -n "${inputs.dod-pki}/DoD_PKE_CA_chain.pem" \
        -i "${inputs.dod-pki}/DoD_PKE_CA_chain.pem"
      fi
    '';
  };
}
