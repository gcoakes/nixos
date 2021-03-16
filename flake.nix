{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixos-wsl = {
      url = "github:gcoakes/NixOS-WSL/modularize";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    "coc.nvim" = {
      url = "github:gcoakes/coc.nvim/release";
      flake = false;
    };
    kitty-themes = {
      url = "github:dexpota/kitty-themes";
      flake = false;
    };
    lutris-skyrimse-installers = {
      url = "github:rockerbacon/lutris-skyrimse-installers";
      flake = false;
    };
    dod-pki = {
      url = "https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/certificates_pkcs7_v5-10_wcf.zip";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, home-manager, flake-utils, nixos-wsl, ... }@inputs:
    let
      homeModules = [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.gcoakes = import ./home.nix inputs;
        }
      ];
      allModules = [ ./common.nix ./system.nix ] ++ homeModules;
    in
      {
        overlays = with builtins; listToAttrs (
          map
            (n: { name = elemAt (split "\\.nix" n) 0; value = import (./overlays + "/${n}") inputs; })
            (filter (n: match ".*\\.nix" n != null) (attrNames (readDir ./overlays)))
        );

        nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          extraArgs = { inherit inputs; };
          modules = allModules ++ [ ./workstation.nix ];
        };
        nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          extraArgs = { inherit inputs; };
          modules = allModules ++ [ ./laptop.nix ];
        };
        nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          extraArgs = { inherit inputs; };
          modules = nixos-wsl.nixosModules ++ [
            ./common.nix
            home-manager.nixosModules.home-manager
            {
              boot.wsl.enable = true;
              boot.wsl.user = "gcoakes";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.gcoakes = import ./wsl-home.nix;
              networking.proxy = {
                default = "http://proxy-chain.intel.com:911";
                noProxy = "127.0.0.1,::1,localhost,.localdomain,.intel.com";
              };
            }
          ];
        };
      } // flake-utils.lib.eachDefaultSystem
        (
          system:
            let
              pkgs = import nixpkgs { inherit system; };
            in
              {
                checks.check-format = pkgs.runCommand "check-format"
                  { buildInputs = with pkgs; [ nixpkgs-fmt ]; } ''
                  nixpkgs-fmt --check ${./.}
                  mkdir $out # success
                '';

                devShell = pkgs.mkShell {
                  nativeBuildInputs = with pkgs; [ nixpkgs-fmt ];
                };
              }
        );
}
