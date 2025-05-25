{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.6-1";
      chartHash = "sha256-DMuSFkVf7LL/9f/eF8P6JStJZu385dQsLRW3esqWqjQ=";
    };
  };
}
