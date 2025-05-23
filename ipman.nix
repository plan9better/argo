{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.3";
      chartHash = "sha256-+iAE3EBCBMq8EamgP8T6fk0uUy0csOQD3ljUljQDxuY=";
    };
  };
}
