{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

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
            config = {
              permittedInsecurePackages = [ "python-2.7.18.8" ];
              allowUnfreePredicate = pkg: lib.hasPrefix "connectiq-sdk" (lib.getName pkg);
            };
          };

          packages = {
            connectiq-sdk = pkgs.callPackage ./connectiq-sdk.nix { };
            gen-dev-key = pkgs.writeShellApplication {
              name = "gen-dev-key";
              runtimeInputs = [ pkgs.openssl ];
              text = ''
                name="''${1:-developer_key}"
                openssl genrsa -out "$name.pem" 4096
                openssl pkcs8 -topk8 -nocrypt -inform PEM -outform DER -in "$name.pem" -out "$name.der"
              '';
            };
            default = self'.packages.connectiq-sdk;
          }
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isx86_64 {
            connectiq-sdk-manager = pkgs.callPackage ./connectiq-sdk-manager.nix { };
          };

          devShells.default = pkgs.mkShell {
            packages = [
              self'.packages.connectiq-sdk
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
              self'.packages.connectiq-sdk-manager
            ];
          };
        };
    };
}
