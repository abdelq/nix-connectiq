{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        {
          self',
          lib,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.permittedInsecurePackages = [ "python-2.7.18.8" ];
            config.allowUnfreePredicate = pkg: lib.getName pkg == "connectiq-sdk";
          };

          packages.default = pkgs.callPackage ./connectiq-sdk.nix { };
          devShells.default = pkgs.mkShell { packages = [ self'.packages.default ]; };
        };
    };
}
