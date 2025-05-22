{
  nixidy = {
    target = {
      repository = "https://github.com/plan9better/argo";
      branch = "nixidy";
      rootPath = "./manifests/prod";
    };
    applicationImports = [
      ./generated/ipman.nix
    ];
  };
  applications.scb-web = {
    namespace = "scb-web";
    createNamespace = true;
    resources = import ./scb-web-deployment.nix;
  };
}
