{
  nixidy = {
    target = {
      repository = "https://github.com/plan9better/argo";
      branch = "master";
      rootPath = "./manifests/prod";
    };
    applicationImports = [
      ./generated/ipman.nix
    ];
  };
  applications.scb-web = {
    namespace = "external-apps";
    resources.namespaces.external-apps.metadata.labels = {
      "pod-security.kubernetes.io/enforce" = "privileged";
      "pod-security.kubernetes.io/enforce-version" = "latest";
      "pod-security.kubernetes.io/warn" = "restricted";
      "pod-security.kubernetes.io/warn-version" = "latest";
    };
    # resources = import ./scb-web-deployment.nix;
    imports = [(import ./ipman.nix)];
  };
}
