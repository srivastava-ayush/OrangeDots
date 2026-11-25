{
  description = "Vendored CLI for Orange OS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs.lib) genAttrs platforms lists systems;

    pkgsOf = nixpkgs.legacyPackages;
    systems' = lists.intersectLists platforms.linux systems.flakeExposed;
    eachSystem = genAttrs systems';
  in {
    formatter = eachSystem (system: pkgsOf.${system}.alejandra);

    packages = eachSystem (system: rec {
      orangeos-cli = pkgsOf.${system}.callPackage ./default.nix {};
      default = orangeos-cli;
    });

    devShells = eachSystem (system: {
      default = pkgsOf.${system}.mkShellNoCC {
        packages = [self.packages.${system}.default];
      };
    });
  };
}
