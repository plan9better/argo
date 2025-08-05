{
  nixidy,
  system,
  ...
}: {
  vlanman = nixidy.packages.${system}.generators.fromCRD {
    name = "vlanman";
    src = ../vlanman-0.1.4.tgz;
    crds = [
      "templates/vlanman.dialo.ai_vlannetworks.yaml"
    ];
  };
}
