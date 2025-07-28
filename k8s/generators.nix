{
  nixidy,
  system,
  ...
}: {
  vlanman = nixidy.packages.${system}.generators.fromCRD {
    name = "vlanman";
    src = ../vlanman-0.1.1.tgz;
    crds = [
      "templates/vlanman-crd.yaml"
    ];
  };
}
