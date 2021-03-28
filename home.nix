inputs:
{ config, pkgs, lib, nixosConfig, ... }:
let
  hasBattery = nixosConfig.networking.hostName == "laptop";
  sauceFont = pkgs.nerdfonts.override { fonts = [ "SourceCodePro" ]; };
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
  wallpaper = builtins.fetchurl {
    url = "https://i.redd.it/u5wugt3u42761.png";
    sha256 = "12g7q1lkkawmswh3xa6lq1cjyxcdck2yvq2xipcrh1lq2s8g0xsp";
  };
  windows-vm = with pkgs;
    writeShellScriptBin "windows-vm" ''
      exec ${qemu_kvm}/bin/qemu-kvm \
        -cpu host \
        -drive file=/mnt/data/qemu/images/win10.qcow2 \
        -net nic \
        -net user,hostfwd=tcp::2223-:22 \
        -m 8G \
        -monitor stdio \
        -name "Windows" \
        $@
    '';
  mo2-handler = with pkgs;
    writeShellScriptBin "modorganizer2-nxm-broker.sh" (
      builtins.readFile
        "${inputs.lutris-skyrimse-installers}/handlers/modorganizer2-nxm-broker.sh"
    );
  mo2-handler-desktop-item = pkgs.makeDesktopItem {
    name = "modorganizer2-nxm-handler";
    desktopName = "Mod Organizer 2 NXM Handler";
    type = "Application";
    categories = "Game;";
    exec = "${mo2-handler}/bin/modorganizer2-nxm-broker.sh %u";
    mimeType = "x-scheme-handler/nxm";
    extraEntries = ''
      NoDisplay=true
    '';
  };
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

  home.packages = with pkgs;
    [
      brave
      cachix
      ccid
      cookiecutter
      deno
      discord
      dmenu
      element-desktop
      ffmpeg
      gimp
      google-chrome
      gpsm
      home-manager
      inkscape
      ipfs
      libreoffice
      lutris
      mo2-handler
      mo2-handler-desktop-item
      neovim-remote
      niv
      opensc
      pass
      pavucontrol
      protontricks
      psm
      sauceFont
      spotify
      steam
      teams
      unzip
      virt-manager
      wineWowPackages.full
      xclip
      yarn
      zip
      zstd
    ] ++ (if hasBattery then [ ] else [ windows-vm ]);

  programs = {
    gpg.enable = true;
    noti.enable = true;
    kitty = {
      enable = true;
      font = {
        name = "SauceCodePro Nerd Font";
        package = sauceFont;
      };
      settings = {
        font_size = if hasBattery then "11.0" else "12.0";
        enable_audio_bell = "no";
      };
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
        "x-scheme-handler/msteams" = [ "teams.desktop" ];
        "x-scheme-handler/nxm" = [ "modorganizer2-nxm-handler.desktop" ];
      };
    };
  };

  fonts.fontconfig.enable = true;

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";
      "org/gnome/desktop/background".picture-uri = "file://${wallpaper}";
      "org/gnome/desktop/screensaver".picture-uri = "file://${wallpaper}";
    };
  };

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
