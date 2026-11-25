{
  description = "Desktop shell for Caelestia dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Vendored CLI — no external caelestia-cli package is required.
    orangeos-cli = {
      url = "path:../../orangeos-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    m3shapes = {
      url = "github:soramanew/m3shapes/bdc327b29f95394a732baf3c9b19658ba23755b6";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: rec {
      caelestia-shell = pkgs.callPackage ./nix {
        inherit (inputs) m3shapes;
        rev = self.rev or self.dirtyRev;
        stdenv = pkgs.clangStdenv;
        quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          withX11 = false;
          withI3 = false;
        };
      };
      debug = caelestia-shell.override {debug = true;};
      default = caelestia-shell;
    });

    devShells = forAllSystems (pkgs: {
      default = let
        shell = self.packages.${pkgs.stdenv.hostPlatform.system}.caelestia-shell;
      in
        pkgs.mkShell.override {stdenv = shell.stdenv;} {
          inputsFrom = [shell shell.plugin shell.extras shell.m3shapesModule];
          packages = with pkgs; [clazy material-symbols rubik nerd-fonts.caskaydia-cove];
          CAELESTIA_XKB_RULES_PATH = "${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst";
        };
    });

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}
