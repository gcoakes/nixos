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

  environment.systemPackages = with pkgs.gnome3; [
    gnome-shell-extensions
    gnome-tweaks
  ];
  services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

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
      gnome3.enable = true;
    };
    displayManager.gdm.enable = true;
  };

  programs.gnupg.agent.pinentryFlavor = "gnome3";
}
