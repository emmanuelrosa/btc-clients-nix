{
  description = "Bitcoin client software packages for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }: let
    lib = nixpkgs.lib;

    # A function to build the `packages` attribute.
    # If available, pkg.meta.platforms is checked for compatibility.
    forAllSystems = func: lib.genAttrs [
      "x86_64-linux"
     "aarch64-linux"
    ] (system:
      lib.filterAttrs
        (pname: pkg: 
          (!(builtins.hasAttr "meta" pkg))
          || (!(builtins.hasAttr "platforms" pkg.meta))
          || (builtins.elem system pkg.meta.platforms))
        (func (import nixpkgs { inherit system; }) system)
    );
  in {
    nixosModules.datum_gateway = import ./modules/datum_gateway/module.nix;
    nixosModules.hashgg = import ./modules/hashgg/module.nix;

    packages = forAllSystems (pkgs: system: rec {
      bisq = pkgs.callPackage ./pkgs/bisq {};
      bisq-desktop = bisq;
      bisq2 = pkgs.callPackage ./pkgs/bisq2 {};
      sparrow = pkgs.callPackage ./pkgs/sparrow {};
      sparrow-get-source-hashes = pkgs.callPackage ./pkgs/sparrow/get-source-hashes.nix {};
      bitcoin-tui = pkgs.callPackage ./pkgs/bitcoin-tui {};
      rpcauth = pkgs.callPackage ./pkgs/rpcauth {};
      datum_gateway = pkgs.callPackage ./pkgs/datum_gateway {};
      playit = pkgs.callPackage ./pkgs/playit {};
      playit-get-source-hashes = pkgs.callPackage ./pkgs/playit/get-source-hashes.nix {};
      hashgg = pkgs.callPackage ./pkgs/hashgg { 
        inherit (self.packages."${system}") playit;
      };

      update-checker = pkgs.callPackage ./pkgs/update-checker {
        inherit (self.packages."${system}")
          bisq
          bisq2
          sparrow
          bitcoin-tui
          rpcauth
          datum_gateway
          playit
          hashgg;
      };
    });
  };
}
