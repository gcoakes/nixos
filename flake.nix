{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
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
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      commonModules = [
        ./common.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.gcoakes = import ./home.nix inputs;
        }
      ];
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
          modules = commonModules ++ [ ./workstation.nix ];
        };
        nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          extraArgs = { inherit inputs; };
          modules = commonModules ++ [ ./laptop.nix ];
        };
      };
}
