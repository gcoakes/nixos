{ config, lib, pkgs, ... }:
let
  unstable = import (pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "0a146054bdf6f70f66de4426f84c9358521be31e";
    sha256 = "154ypjfhy9qqa0ww6xi7d8280h85kffqaqf6b6idymizga9ckjcd";
  }) { };
in {
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
      defaultFonts.monospace = [ "Hasklug Nerd Font Complete" ];
    };
    fonts = with pkgs;
      [ (unstable.nerdfonts.override { fonts = [ "Hasklig" ]; }) ];
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
    desktopManager = {
      xterm.enable = false;
      session = [{
        name = "home-manager";
        bgSupport = true;
        start = ''
          ${pkgs.runtimeShell} $HOME/.hm-xsession &
          waitPID=$!
        '';
      }];
    };
    displayManager = {
      lightdm.enable = true;
      defaultSession = "home-manager";
    };
  };

  programs.gnupg.agent.pinentryFlavor = "gtk2";
  programs.dconf.enable = true;
}
