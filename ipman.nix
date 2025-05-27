{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.7-2";
      chartHash = "sha256-hWMkNm3jawvreMpxmYw2qJfTQ0fo+RwqM2jnhFfGQZY=";
    };
  };
}
