{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixidy.url = "github:dialohq/nixidy/d010752e7f24ddaeedbdaf46aba127ca89d1483a";
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

        nixidyEnvs = nixidy.lib.mkEnvs {
          inherit pkgs;

          envs = {
            prod.modules = [./prod.nix];
          };
        };
      in {
        packages = {
          generators.ipman = nixidy.packages.${system}.generators.fromCRD {
            name = "ipman";
            src = pkgs.fetchFromGitHub {
              owner = "dialohq";
              repo = "ipman";
              rev = "master";
              hash = "sha256-LtXy2pvFkGNMggE2eiwV+ofk+1Xxsmx012Zf11jwtSY=";
            };
            crds = [
              "ipman/templates/ipman-crd.yaml"
            ];
          };
        };
        inherit nixidyEnvs;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            go
            gopls
            gnumake
            tokei # loc count
            dockerfile-language-server-nodejs
            yaml-language-server
            yamlfmt
            kuttl # kubernetes tests
            kubernetes-helm
            helm-ls
            nixidy.packages.${system}.default
            argocd
          ];
          shellHook = ''
            zsh
          '';
          env = {
            KUBECONFIG = "/Users/patrykwojnarowski/dev/work/kubeconfig";
            EDITOR = "hx";
          };
        };
      }
    );
}
