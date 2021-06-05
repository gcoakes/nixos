{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    picom = {
      url = "github:ibhagwan/picom";
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
  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let sharedModules = [ (import ./modules) ./common.nix ];
    in rec {
      nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = sharedModules ++ [ ./system/workstation.nix ];
        extraArgs = { inherit inputs; };
      };
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = sharedModules ++ [ ./system/laptop.nix ];
        extraArgs = { inherit inputs; };
      };
      nixosModule = import ./modules;
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShell = pkgs.mkShell {
          inputsFrom = [
            (pkgs.haskellPackages.callPackage ./overlays/xmonad-config { }).env
          ];
          nativeBuildInputs = with pkgs; [ nixfmt stylish-haskell ];
        };
      });
}
