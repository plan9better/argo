{lib, ...}: {
  nixidy.target.repository = "https://github.com/plan9better/argo.git";
  nixidy.target.branch = "master";
  nixidy.target.rootPath = "./manifests/dev";

  nixidy.applicationImports = [
    ../k8s/crds/vlanman.nix
  ];
  applications.vlanman = {
    imports = [((import ./vlanman.nix) {inherit lib;})];
  };
}
