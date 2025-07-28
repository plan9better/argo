{...}: {
  nixidy.target.repository = "https://github.com/plan9better/argo.git";
  nixidy.target.branch = "master";
  nixidy.target.rootPath = "./manifests/dev";
}
