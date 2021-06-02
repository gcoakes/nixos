{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    dracula-sublime = {
      url = "github:dracula/sublime";
      flake = false;
    };
    kitty-themes = {
      url = "github:dexpota/kitty-themes";
      flake = false;
    };
    dod-pki = {
      url =
        "https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/certificates_pkcs7_v5-10_wcf.zip";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, home-manager, flake-utils, ... }@inputs:
    let
      systemModules =
        [ ./common.nix ./system.nix home-manager.nixosModules.home-manager ];
    in rec {
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
        devShell = pkgs.mkShell {
          inputsFrom = [ (pkgs.haskellPackages.callPackage ./xmonad { }).env ];
          nativeBuildInputs = with pkgs; [ nixfmt stylish-haskell ];
        };
      });
}
