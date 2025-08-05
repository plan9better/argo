{lib, ...}: {
  nixidy.target.repository = "https://github.com/plan9better/argo.git";
  nixidy.target.branch = "master";
  nixidy.target.rootPath = "./manifests/dev";

  nixidy.applicationImports = [
    ../k8s/crds/vlanman.0.1.4.nix
  ];
  applications.vlanman = {
    namespace = "vlanman";
    resources.namespaces.vlanman.metadata.labels = {
      "pod-security.kubernetes.io/enforce" = "privileged";
      "pod-security.kubernetes.io/enforce-version" = "latest";
      "pod-security.kubernetes.io/warn" = "restricted";
      "pod-security.kubernetes.io/warn-version" = "latest";
    };

    imports = [((import ./vlanman.nix) {inherit lib;})];
  };
}
