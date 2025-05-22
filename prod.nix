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
    resources = import ./scb-web-deployment.nix;
  };
}
