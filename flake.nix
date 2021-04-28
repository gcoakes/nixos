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
    dracula-sublime = {
      url = "github:dracula/sublime";
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
      url =
        "https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/certificates_pkcs7_v5-10_wcf.zip";
      flake = false;
    };
    vim-licenses = {
      url = "github:antoyo/vim-licenses";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, home-manager, flake-utils, nixos-wsl, ... }@inputs:
    let
      systemModules =
        [ ./common.nix ./system.nix home-manager.nixosModules.home-manager ];
    in {
      nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        extraArgs = { inherit inputs; };
        modules = systemModules ++ [ ./workstation.nix ];
      };
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        extraArgs = { inherit inputs; };
        modules = systemModules ++ [ ./laptop.nix ];
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        checks.check-format = pkgs.runCommand "check-format" {
          buildInputs = with pkgs; [ nixpkgs-fmt ];
        } ''
          nixpkgs-fmt --check ${./.}
          mkdir $out # success
        '';

        devShell = pkgs.mkShell {
          inputsFrom = [ (pkgs.haskellPackages.callPackage ./xmonad { }).env ];
          nativeBuildInputs = with pkgs; [ nixpkgs-fmt ormolu ];
        };
      });
}
