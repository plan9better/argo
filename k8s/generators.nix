{
  nixidy,
  system,
  pkgs,
  ...
}: {
  vlanman = nixidy.packages.${system}.generators.fromCRD {
    name = "vlanman";
    src = pkgs.fetchurl {
      url = "https://github.com/dialohq/vlanman/releases/download/v0.1.5/vlanman-0.1.5.tgz";
      hash = "sha256-NKUKapXXwXH1l8/yr7eGuBSeyxGwXRmfHJMDTc1zCc8=";
    };
    crds = [
      "templates/vlanman.dialo.ai_vlannetworks.yaml"
    ];
  };
}
