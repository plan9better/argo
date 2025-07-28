{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixidy.url = "github:arnarg/nixidy";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    nixidy,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        nixidyEnvs = nixidy.lib.mkEnvs {
          inherit pkgs;

          envs = {
            dev.modules = [./env/dev.nix];
          };
        };

        packages = {
          nixidy = nixidy.packages.${system}.default;
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [glow nixidy.packages.${system}.default];
        };
      }
    );
}
