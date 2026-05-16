{
  description = "Bitcoin client software packages for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }: {

    nixosModules.datum_gateway = import ./modules/datum_gateway/module.nix;
    nixosModules.hashgg = import ./modules/hashgg/module.nix;

    packages.x86_64-linux = let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
    in {
      bisq = pkgs.callPackage ./pkgs/bisq {};
      bisq-desktop = self.packages."${system}".bisq;
      bisq2 = pkgs.callPackage ./pkgs/bisq2 {};
      sparrow = pkgs.callPackage ./pkgs/sparrow {};
      sparrow-get-source-hashes = pkgs.callPackage ./pkgs/sparrow/get-source-hashes.nix {};
      bitcoin-tui = pkgs.callPackage ./pkgs/bitcoin-tui {};
      rpcauth = pkgs.callPackage ./pkgs/rpcauth {};
      datum_gateway = pkgs.callPackage ./pkgs/datum_gateway {};
      playit = pkgs.callPackage ./pkgs/playit {};
      playit-get-source-hashes = pkgs.callPackage ./pkgs/playit/get-source-hashes.nix {};
      hashgg = pkgs.callPackage ./pkgs/hashgg { 
        inherit (self.packages.x86_64-linux) playit;
      };

      update-checker = pkgs.callPackage ./pkgs/update-checker {
        inherit (self.packages.x86_64-linux)
          bisq
          bisq2
          sparrow
          bitcoin-tui
          rpcauth
          datum_gateway
          playit
          hashgg;
      };
    };

    packages.aarch64-linux = let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
    in {
      sparrow = pkgs.callPackage ./pkgs/sparrow {};
      sparrow-get-source-hashes = pkgs.callPackage ./pkgs/sparrow/get-source-hashes.nix {};
      bisq2 = pkgs.callPackage ./pkgs/bisq2 {};
      bitcoin-tui = pkgs.callPackage ./pkgs/bitcoin-tui {};
      rpcauth = pkgs.callPackage ./pkgs/rpcauth {};
      datum_gateway = pkgs.callPackage ./pkgs/datum_gateway {};
      playit = pkgs.callPackage ./pkgs/playit {};
    };
  };
}
