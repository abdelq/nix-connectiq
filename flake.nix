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
            config.allowUnfreePredicate = pkg: lib.hasPrefix "connectiq-sdk" (lib.getName pkg);
          };

          packages = {
            connectiq-sdk = pkgs.callPackage ./connectiq-sdk.nix { };
            connectiq-sdk-manager = pkgs.callPackage ./connectiq-sdk-manager.nix { };
            default = self'.packages.connectiq-sdk;
          };

          devShells.default = pkgs.mkShell {
            packages = with self'.packages; [
              connectiq-sdk
              connectiq-sdk-manager
            ];
          };
        };
    };
}
