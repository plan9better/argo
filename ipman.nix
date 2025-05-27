{lib, ...}: {
  helm.releases.ipman = {
    chart = lib.helm.downloadHelmChart {
      repo = "https://dialohq.github.io/ipman";
      chart = "ipman";
      version = "0.0.7";
      chartHash = "sha256-vUdhWq86YoouJyYYsYpw5vbPvm7ALzCYV2uT/5l22l0=";
    };
  };
}
