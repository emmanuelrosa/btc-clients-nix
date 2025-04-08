{
  description = "Bitcoin client software packages for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    oldNixpkgs.url = "github:nixos/nixpkgs?ref=6710d0dd013f55809648dfb1265b8f85447d30a6";
  };

  outputs = { self, nixpkgs, oldNixpkgs }: {

    packages.x86_64-linux = let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
      oldPkgs = oldNixpkgs.legacyPackages."${system}";
    in {
      bisq = oldPkgs.callPackage ./pkgs/bisq {};
      bisq-desktop = self.packages."${system}".bisq;
      bisq2 = pkgs.callPackage ./pkgs/bisq2 {};
      openimajgrabber = pkgs.callPackage ./pkgs/openimajgrabber {};

      sparrow = pkgs.callPackage ./pkgs/sparrow {
        openimajgrabber = self.packages."${system}".openimajgrabber; 
      };
    };
  };
}
